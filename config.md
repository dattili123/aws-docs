Yes — since you already have a **centralized AWS Config aggregator**, you can absolutely leverage AWS **Config + Config Aggregator + CloudTrail Lookup** to detect which IAM roles listed in the `sts:AssumeRole` inline policy **have not been assumed** in the past 90 days. Here's a tailored solution:

---

## ✅ **Objective Recap**

* In 200 AWS accounts, find all `prod*comp` IAM roles.
* Each such role has an inline policy granting `sts:AssumeRole` to \~140 other IAM roles.
* Identify which of those target roles have **not been assumed by any `prod*comp` role in the last 90 days**.

---

## ✅ How AWS Config Helps

AWS Config **records IAM role resources and their inline policies**, and **stores them centrally via your aggregator**.

However, **AWS Config alone doesn’t log API activity** (like actual `AssumeRole` usage) — that’s **CloudTrail’s job**.

So, you’ll use both:

| Service                         | Role                                                                               |
| ------------------------------- | ---------------------------------------------------------------------------------- |
| **AWS Config Aggregator**       | To extract `prod*comp` roles + inline `sts:AssumeRole` permissions across accounts |
| **CloudTrail (Lake or Lookup)** | To detect if `AssumeRole` was actually called by those roles                       |

---

## 🧭 Step-by-Step with Config Aggregator

---

### 🔍 1. **Query `prod*comp` roles across all accounts**

Use AWS Config Aggregator's `SelectResourceConfig` API.

#### Example query:

```sql
SELECT
  accountId,
  resourceId,
  resourceName,
  configuration.roleName,
  configuration.rolePolicyList
WHERE
  resourceType = 'AWS::IAM::Role'
  AND resourceName LIKE 'prod%comp'
```

You can run this from the **Config Aggregator's home region** using:

```bash
aws configservice select-aggregate-resource-config \
  --configuration-aggregator-name <aggregator-name> \
  --expression "..." \
  --region <aggregator-region>
```

#### 🔍 Output:

This gives you:

* The IAM role name (`prod*comp`)
* Its inline policy contents (`rolePolicyList`)
* The list of `sts:AssumeRole` ARNs granted

---

### 📜 2. **Extract all ARNs in `sts:AssumeRole` policies**

Parse the `rolePolicyList` and pull out all `Resource` ARNs where `Action` includes `sts:AssumeRole`.

#### Example inline policy:

```json
{
  "PolicyName": "AllowAssumeRoles",
  "PolicyDocument": {
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Resource": [
          "arn:aws:iam::123456789012:role/TargetRole1",
          "arn:aws:iam::123456789013:role/TargetRole2"
        ]
      }
    ]
  }
}
```

---

### 🕵️ 3. **Query CloudTrail to check if assumption happened**

Now for each target role ARN:

* Query CloudTrail Lake (preferred) or Lookup Events (limited) to check if it was assumed
* Filter by:

  * `eventName = 'AssumeRole'`
  * `requestParameters.roleArn = '<target role>'`
  * `userIdentity.arn = 'arn:aws:iam::<acc>:role/prod*comp'`

#### 📘 CloudTrail Lake SQL Example:

```sql
SELECT
  eventTime,
  requestParameters.roleArn,
  userIdentity.arn AS callingRole
FROM
  cloudtrail_event_data_store
WHERE
  eventName = 'AssumeRole'
  AND requestParameters.roleArn = 'arn:aws:iam::123456789012:role/TargetRole1'
  AND userIdentity.arn LIKE 'arn:aws:iam::%:role/prod%comp'
  AND eventTime > date_sub(current_date, interval 90 day)
```

> 🔁 Loop through all role ARNs extracted from AWS Config.

---

## 🛠️ Automation Plan

| Step                       | Tool                       | Notes                                  |
| -------------------------- | -------------------------- | -------------------------------------- |
| 1. Query `prod*comp` roles | AWS Config Aggregator      | via `select-aggregate-resource-config` |
| 2. Parse inline policies   | Python/Script              | extract `sts:AssumeRole` resources     |
| 3. Check role assumption   | CloudTrail Lake SQL or API | match calling role and target ARN      |
| 4. Output                  | CSV / S3 report            | Include `used/not-used` with timestamp |

---

## 📦 Final Output Example

| Source Account | `prod*comp` Role | Target IAM Role | Last AssumeTime | Status     |
| -------------- | ---------------- | --------------- | --------------- | ---------- |
| 111111111111   | prodXcomp        | role-A          | 2025-06-12      | ✅ Used     |
| 111111111111   | prodXcomp        | role-B          | —               | ❌ Not Used |

---

## 💡 Tip: Centralize Logs for Easier Access

To make this **scalable**, forward **all 200 accounts’ CloudTrail logs to one central Lake**. That way:

* You only need to run your queries **once from a single account**.
* No need to assume into 200 accounts.

---

## ✅ Want a ready-to-run script?

I can provide a **Python script** that:

* Queries Config Aggregator to get `prod*comp` roles and `sts:AssumeRole` ARNs
* Queries CloudTrail Lake for those ARNs
* Generates a report of unused roles in 90 days

Would you like me to generate that script?
