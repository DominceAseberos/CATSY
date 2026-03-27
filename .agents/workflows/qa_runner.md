---
description: QA testing workflow — systematically run through unfinished test cases
---

# QA Testing Runner Workflow

This workflow is to be used when assisting the user with Quality Assurance (QA) and test case execution.

## Core Rules

1. **Scan `test_cases.md` for Unfinished Tests**
   - Read the `test_cases.md` file starting from the top.
   - Look for the first test case that has a `Status` of `pending`, `incorrect`, `fail`, or is completely empty.

2. **Present the Next Unfinished Test Case**
   - Present the FIRST unfinished test case you find to the user using the `notify_user` tool.
   - Include the **Test ID**, **Module**, **Scenario**, **Test Steps**, and **Expected Result**.
   - Ask the human to manually execute these steps and report back the outcome.

3. **Wait for Human Action**
   - Stop and wait for the user to confirm the actual outcome. 
   - **CRITICAL**: The AI must **NEVER** mark a test `pass` or `fail` on its own. The Status column is purely driven by human feedback.

4. **Update the Test Document**
   - Once the human provides the outcome, update the `Actual Outcome` and `Status` column for that specific test case in the `test_cases.md` file.

5. **Evaluate Section Verification Status**
   - After updating the test case, check the entire section/table that the test case belongs to.
   - If **every single** test case in that section now has a status of `pass`:
     - Update the section header text to `*Verified Date: YYYY-MM-DD*` (using the current date).
   - If **any** test case in that section still has a status of `pending`, empty, `fail`, or `incorrect`:
     - DO NOT update the header to "Verified Date". Ensure it says `*Last Updated: YYYY-MM-DD*`.

6. **Iterate**
   - Ask the user if they want to proceed to the next unfinished test case, and loop back to Step 1.
