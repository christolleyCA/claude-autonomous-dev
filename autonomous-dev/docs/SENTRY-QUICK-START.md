# Sentry Integration - Quick Start

**Fast setup guide for NFP Website Finder monitoring**

---

## 🚀 5-Minute Setup

### Step 1: Create Sentry Project (2 minutes)

1. Go to: https://oxfordshire-inc.sentry.io
2. Click **Projects** → **Create Project**
3. Select **Node.js** platform
4. Name: `nfp-website-finder`
5. Click **Create Project**
6. **Copy the DSN** (looks like: `https://abc123@oxfordshire-inc.ingest.us.sentry.io/123456`)

### Step 2: Add to N8N Workflow (3 minutes)

1. **Open your NFP Website Finder workflow in n8n**
2. **Add a Code node at the START** of your workflow
3. **Name it:** "Sentry Helper"
4. **Copy code from:** `autonomous-dev/config/sentry-n8n-snippets.js` (SNIPPET 1)
5. **Replace** `YOUR_DSN_HERE` with your actual DSN
6. **Save and activate** the node

### Step 3: Add Tracking Points

Add Code nodes at these key points in your workflow:

| **When** | **Use Snippet** | **Node Name** |
|----------|----------------|---------------|
| Workflow starts | Snippet 2 | Track Workflow Started |
| Before batch processing | Snippet 3 | Track Batch Started |
| Gemini API calls | Snippet 4 | Gemini API with Sentry |
| After batch completes | Snippet 5 | Track Batch Completed |
| Milestones (100, 500, 1000 rows) | Snippet 6 | Track Milestone |
| Error handling | Snippet 7 | Track Error |
| Workflow ends | Snippet 8 | Track Workflow Completed |

---

## 📊 What You'll See in Sentry

After running your workflow, go to Sentry:

### Issues Tab
- All errors and exceptions
- Stack traces for debugging
- Grouped by error type

### Performance Tab
- Gemini API response times
- Batch processing duration
- Success rates per processor

### Discover Tab
Create custom queries:
```
event.type:default AND tags[event_type]:workflow_started
```

---

## 🎯 Key Metrics Tracked

| **Metric** | **Target** | **What It Means** |
|------------|------------|-------------------|
| Average batch time | < 60s | How long each batch takes |
| Gemini API response | < 30s | API call performance |
| Sheets update time | < 5s | Google Sheets write speed |
| Success rate | > 95% | Rows processed successfully |

---

## 🔔 Set Up Alerts (Recommended)

1. Go to **Alerts** → **Create Alert**
2. Create these alerts:
   - **High Error Rate:** > 5% errors in 1 hour
   - **Slow Batch:** Average batch time > 90 seconds
   - **Low Success Rate:** < 90% success rate

---

## 📁 Files Created

| **File** | **Purpose** |
|----------|------------|
| `docs/NFP-WEBSITE-FINDER-SENTRY-SETUP.md` | Complete setup guide |
| `config/sentry-n8n-snippets.js` | Copy-paste code snippets |
| `docs/SENTRY-QUICK-START.md` | This file |

---

## 🆘 Troubleshooting

**Events not showing up?**
- ✅ Check DSN is correct in Sentry Helper node
- ✅ Test with a small workflow first
- ✅ Check Sentry project status

**Too many events?**
- Add sampling logic (track only 10% of batch_completed events)
- Focus on errors and milestones only

**Need more details?**
- Read: `docs/NFP-WEBSITE-FINDER-SENTRY-SETUP.md`

---

## 💡 Pro Tips

1. **Start simple:** Add Sentry Helper + Track Errors first
2. **Test small:** Run 10 rows first to verify tracking works
3. **Check daily:** Review Sentry dashboard for trends
4. **Set alerts:** Get notified when things go wrong
5. **Use tags:** Filter by `processor_id` to debug specific processors

---

**Ready to go!** 🎉

Your Sentry integration is configured and ready to track your NFP Website Finder workflow.
