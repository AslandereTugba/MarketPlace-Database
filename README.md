# Marketplace Database 

A SQL Server database design for a subscription-based learning marketplace where students can:
- subscribe to plans (quota-based question asking),
- upload/sell notes,
- ask & answer questions,
- rate content,
- and automatically track payments (purchases, payouts, subscriptions).

## Key Features
- **Relational schema with strong integrity**: PK/FK, UNIQUE, CHECK constraints
- **Business rules enforced in the DB**
  - Only **one active subscription per student** (filtered unique index + procedure validation)
  - Automatic **payment creation** on:
    - note purchase (buyer payment + seller payout)
    - verified answers (answer payout)
- **Reporting views** for quick insights (rating summary, Q&A summary)
- **Seed data + demo queries** included to validate the workflow end-to-end

## What’s Inside
- `MarketPlace_Database*.sql`  
  Creates the database, tables, indexes, views, stored procedures, triggers, inserts sample data, and runs demo queries.
- `ClassDiagram*.png`  
  ER-style overview diagram.
- `LogicalDiagram*.png`  
  Logical/relational model view.
- `*ProjectReport.pdf`  
  Project workflow + diagrams (documentation).

## Database Objects (Summary)
**Tables (13):** Student, Course, Plan, Transcript, Subscription, SubscriptionUsage, Question, Answer, Note, Purchase, NoteRating, AnswerRating, Payment  
**Views (2):** `vw_NoteRatingSummary`, `vw_QuestionAnswerSummary`  
**Stored Procedures (2):**
- `sp_SubscribeStudent` (creates subscription + subscription payment)
- `sp_PurchaseNote` (creates purchase; payments are handled by trigger)
**Triggers (2):**
- `trg_Purchase_CreatePayments` (note_purchase + note_payout)
- `trg_Answer_Verified_CreatePayment` (answer_payout)

## Quick Start (SQL Server)
> ⚠️ **Important:** The script drops and recreates the database. Run it only in a safe/local environment.

1. Open **SQL Server Management Studio (SSMS)**.
2. Open the SQL script file: `MarketPlace_Database*.sql`.
3. Execute the script.
4. Verify:
   - Subscription payment is created after `sp_SubscribeStudent`
   - Two payments are created after `sp_PurchaseNote`
   - Answer payout is created after updating an answer to `verified`

### Example Calls
```sql
EXEC dbo.sp_SubscribeStudent @student_id = 1, @plan_id = 2;
EXEC dbo.sp_PurchaseNote @buyer_student_id = 1, @note_id = 3;

UPDATE dbo.Answer
SET status = 'verified'
WHERE answer_id = 1;
