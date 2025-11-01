# 🚀 SIMPLE INSTRUCTIONS: Fix Corrupted Names in 3 Minutes

## What is psql?
`psql` is a command-line tool for talking to PostgreSQL databases (which is what Supabase uses). It's already installed on your Mac, and it can read our big SQL file and apply all the fixes at once.

---

## Step 1: Get Your Database Password

1. Go to this link: https://supabase.com/dashboard/project/hjtvtkffpziopozmtsnb/settings/database
2. Scroll down to the section called **"Database password"**
3. Click **"Reset database password"** if you don't know it, or just copy it if you do
4. Copy the password and save it somewhere temporarily (you'll need it in a minute)

---

## Step 2: Open Terminal

1. Press `Command + Space` (to open Spotlight)
2. Type: `Terminal`
3. Press Enter

You'll see a black or white window with some text - this is your terminal.

---

## Step 3: Run This Command

Copy this ENTIRE command and paste it into Terminal:

```bash
PGPASSWORD='PUT-YOUR-PASSWORD-HERE' psql \
  -h aws-0-ca-central-1.pooler.supabase.com \
  -p 6543 \
  -U postgres.hjtvtkffpziopozmtsnb \
  -d postgres \
  -f ~/MASTER_name_fixes.sql
```

**IMPORTANT:** Before pressing Enter, replace `PUT-YOUR-PASSWORD-HERE` with your actual database password from Step 1.

**Example:** If your password is `abc123xyz`, the first line should look like:
```bash
PGPASSWORD='abc123xyz' psql \
```

---

## Step 4: Press Enter and Wait

After you press Enter:
- You'll see a bunch of text scrolling by (these are the UPDATE statements running)
- It will take about 2-3 minutes
- When it's done, you'll see your normal terminal prompt again (something like `yourusername@MacBook ~ %`)

**Don't close the terminal window while it's running!**

---

## Step 5: Verify It Worked

Go back to Supabase and run this query to check:

https://supabase.com/dashboard/project/hjtvtkffpziopozmtsnb/sql

Click "New Query" and paste this:

```sql
SELECT ein_charity_number, name, website
FROM nonprofits
WHERE ein_charity_number IN ('260418421', '352030346', '460682168')
ORDER BY ein_charity_number;
```

Click "Run"

**You should see:**
- Row 1: `260418421` | `Innovations Academy` | `https://innovationsacademy.org` ✅
- Row 2: `352030346` | `Insight Development Corporation` | `https://www.indyhousing.org` ✅
- Row 3: `460682168` | (correct org name, not "OPTIMAL FINANCIAL GROUP") ✅

If the names look right (not accounting firm names), **it worked!** 🎉

---

## Troubleshooting

### If you see: "psql: command not found"
Run this first:
```bash
brew install postgresql
```
Then try the main command again.

### If you see: "password authentication failed"
Your password is wrong. Go back to Step 1 and reset your database password.

### If you see: "No such file or directory: ~/MASTER_name_fixes.sql"
The file is missing. Let me know and I'll regenerate it.

### If nothing happens for more than 5 minutes
Something is stuck. Press `Control + C` to cancel, then let me know.

---

## What This Command Does (Explained Simply)

- `PGPASSWORD='...'` - Provides your database password
- `psql` - The PostgreSQL command-line tool
- `-h aws-0-ca-central-1.pooler.supabase.com` - Connects to your Supabase database
- `-p 6543` - Uses the correct port number
- `-U postgres.hjtvtkffpziopozmtsnb` - Uses your Supabase username
- `-d postgres` - Connects to the "postgres" database
- `-f ~/MASTER_name_fixes.sql` - Reads and executes all the UPDATE statements from the file

**In plain English:** "Connect to my Supabase database and run all the fixes in the MASTER_name_fixes.sql file"

---

## Summary

1. Get password from Supabase dashboard
2. Open Terminal
3. Copy/paste command (with your password)
4. Wait 2-3 minutes
5. Check if it worked

That's it! 🚀
