# 📚 Knowledge Base - Automatic Learning System

**Status:** ✅ Fully Integrated and Automatic
**Location:** Supabase database + local scripts
**Last Updated:** 2025-11-01

---

## 🎯 TL;DR - How It Works

**The knowledge base is AUTOMATIC.** You don't need to do anything special!

```
Build a feature → Knowledge Base auto-searches → Applies learnings → Logs new solution
```

**Every build automatically:**
1. ✅ Checks KB for similar solutions BEFORE planning
2. ✅ Applies proven patterns to new features
3. ✅ Logs new solutions AFTER completion
4. ✅ Gets smarter every time

---

## 🔄 Automatic Integration Points

### 1. In `build-feature.sh` (Lines 133-174)

**Phase 0: Knowledge Base Check**

```bash
# AUTOMATICALLY RUNS BEFORE EVERY BUILD
check_knowledge_base() {
    # Searches for similar features
    # Saves insights to knowledge-base-insights.txt
    # Notifies you in Slack
}
```

**What happens:**
```
/cc build-feature my-workflow "Add Sentry tracking"
    ↓
🔍 Phase 0: Knowledge Base Check...
    ↓
💡 Found: "Sentry Integration in N8N Workflows"
    ↓
📋 Applying proven patterns...
```

### 2. In Planning Phase (Lines 187-207)

**Incorporates KB Insights into Claude's Plan**

```bash
# KB insights are automatically added to Claude's planning prompt
if KB has relevant solutions:
    Add this to planning context:
    "IMPORTANT - KNOWLEDGE BASE INSIGHTS:
     We have previous experience with this pattern..."
```

**Result:** Claude plans your feature using proven solutions from day 1!

### 3. Post-Build Logging (Lines 816-852)

**Automatically Logs New Solutions**

```bash
# RUNS AFTER EVERY SUCCESSFUL BUILD
if this is a new pattern OR there were challenges:
    log_solution to database
    "✅ Solution logged to knowledge base"
```

**The system decides what to log:**
- New patterns (first time doing something)
- Challenges that were overcome
- Interesting integrations

---

## 📖 When You DON'T Need to Reference It

### Automatic Scenarios (No Action Needed)

✅ **Building features** - KB auto-checks
```bash
./build-feature.sh my-feature "description"
# Phase 0 automatically searches KB
```

✅ **Planning** - KB insights auto-included
```bash
# Claude automatically receives KB context
# in the planning prompt
```

✅ **Completion** - Solutions auto-logged
```bash
# After successful build, solution is logged
# if it's new or interesting
```

---

## 🔍 When You SHOULD Reference It

### Manual Search Scenarios

#### 1. Before Starting Work (Proactive)

**Good practice:** Search before building
```bash
# Check if someone already solved this
./solution-searcher.sh "sentry n8n"
./solution-searcher.sh "rate limiting"
./solution-searcher.sh "database timeout"
```

**Why:** Saves time even before starting the build

#### 2. Debugging Issues (Reactive)

**When stuck:** Search by error message
```bash
source ./solution-searcher.sh
find_by_error "fetch is not defined"
find_by_error "Cannot find module"
```

**Why:** Instantly find solutions to known problems

#### 3. Learning from History

**Review patterns:** See what works
```bash
./view-solutions.sh recent 10    # Recent solutions
./view-solutions.sh top 10       # Most successful
./view-solutions.sh stats        # Overview
```

**Why:** Understand your team's patterns

#### 4. From Slack (Remote)

**When away from computer:**
```
/cc search-solutions "webhook trigger"
/cc view-stats
/cc show-recent-solutions
```

**Why:** Access knowledge base from anywhere

---

## 💡 Best Practices

### For Autonomous Operation

**✅ DO:**
- Let the system work automatically
- Trust the auto-search in Phase 0
- Review KB insights when they appear
- Build features normally - KB works in background

**❌ DON'T:**
- Manually search before every build (it's automatic!)
- Skip Phase 0 (it's fast and valuable)
- Ignore KB insights in Slack notifications
- Worry about logging solutions (automatic!)

### For Maximum Value

**1. Pay Attention to Phase 0 Results**

When you see this in Slack:
```
💡 Knowledge Base Check
Found relevant solutions in knowledge base!
These will be incorporated into the planning phase.
```

**Action:** Review the insights file to understand what patterns will be applied

**2. Read KB Insights Before Planning**

```bash
# After Phase 0, check what was found
cat /tmp/autonomous-builds/my-feature-*/knowledge-base-insights.txt
```

**Why:** Understand what proven patterns Claude will use

**3. Review Growth Over Time**

```bash
# Monthly check
./view-solutions.sh stats
```

**Watch:**
- Total solutions growing
- Success rates improving
- Common tags (your pain points)
- Build times decreasing

---

## 📊 Knowledge Base Dashboard

### View Your Learning Progress

```bash
# Quick stats
./view-solutions.sh stats

Output:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 KNOWLEDGE BASE STATISTICS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 Total Solutions: 6
🏆 Most Used: Git automation patterns
🏷️  Top Tags: git, sentry, n8n, autonomous-development
📈 New this week: 2
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Search Interface

```bash
# Interactive mode
./view-solutions.sh interactive

Commands available:
  <search>      - Search by text
  tags <tags>   - Search by tags
  error <msg>   - Search by error
  stats         - Show statistics
  recent        - Recent solutions
  quit          - Exit
```

---

## 🚀 Integration in GETTING-STARTED.md

### Current Status: ✅ Already Referenced

**In GETTING-STARTED.md (lines 176-181):**
```markdown
#### Knowledge Base:
```
/cc search-solutions "database timeout"
/cc show-recent-solutions
/cc view-stats
```
```

**In GETTING-STARTED.md (lines 489-491):**
```markdown
### Tip 5: Knowledge base grows over time
- Every build adds to the knowledge base
- System gets smarter automatically
- View progress: `./view-solutions.sh stats`
```

### Recommendation: Keep As Is

The documentation **correctly positions** the KB as:
1. **Automatic** (doesn't require manual action)
2. **Background** (works during builds)
3. **Optional for manual search** (when you want to look something up)

---

## 🎓 Teaching Claude About the KB

### When Starting a New Session

**Minimal approach (recommended):**
```
I have an autonomous development system.
Check GETTING-STARTED.md for context.
I want to [your task].
```

Claude will read GETTING-STARTED.md and understand the KB is available.

**Explicit approach (when KB is relevant):**
```
I have an autonomous development system with a knowledge base.
Check GETTING-STARTED.md for context.
Before we start, search the knowledge base for: "sentry integration"
```

**Maximum context (for complex tasks):**
```
I have an autonomous development system:
- Knowledge base with 6 solutions (Supabase DB)
- Auto-integration in build-feature.sh
- Scripts: solution-searcher.sh, view-solutions.sh

Check these docs:
- GETTING-STARTED.md
- KNOWLEDGE-BASE-COMPLETE.md
- SENTRY-N8N-AUTONOMOUS-INTEGRATION-COMPLETE.md

I want to [your complex task that might benefit from KB].
```

---

## 📝 Example: Sentry Integration (New!)

### How the System Used the KB

**Solution Added:** 2025-11-01
**ID:** `1d2638af-c4a2-4d4d-81f9-e78a14cf2c3d`

**If someone builds a Sentry feature tomorrow:**

```bash
./build-feature.sh my-sentry-workflow "Add error tracking"
```

**What happens automatically:**

```
Phase 0: Knowledge Base Check...
🔍 Searching for: "my-sentry-workflow Add error tracking"

💡 Found 1 solution:
📋 Sentry Integration in N8N Workflows for Autonomous Development
🏷️  Tags: sentry, n8n, autonomous-development, webhook, mcp
📊 Used 0 times | Success rate: 100%

Key insights:
❌ Don't use fetch() in Code nodes (not available)
❌ Don't use $http.request() (not available)
✅ Use HTTP Request nodes for external API calls
✅ Use Code nodes for data preparation only
✅ Use direct node references after HTTP nodes
✅ Add OPENAI_API_KEY to Sentry MCP config

Applying these patterns to your plan...
```

**Result:**
- Claude builds it correctly the first time
- No debugging needed
- 55 minutes saved!

---

## 🔧 Maintenance

### Regular Tasks (Optional)

**Monthly:**
```bash
# Check growth
./view-solutions.sh stats

# Review top patterns
./view-solutions.sh top 10

# See what's new
./view-solutions.sh recent 10
```

**When Needed:**
```bash
# Manual logging (rare - usually automatic)
./solution-logger.sh

# Search for specific pattern
./solution-searcher.sh "your search"
```

### Backup (Automatic)

Knowledge base is stored in **Supabase** (cloud):
- ✅ Automatically backed up
- ✅ Persists forever
- ✅ Accessible from anywhere
- ✅ Survives laptop restarts

---

## ❓ FAQ

### Q: Do I need to reference the KB in every prompt?
**A:** No! It's automatic in `build-feature.sh`

### Q: What if Claude doesn't know about the KB?
**A:** Just mention: "Check GETTING-STARTED.md" - Claude will read it

### Q: Should I manually search before building?
**A:** Optional! Phase 0 does it automatically, but manual search doesn't hurt

### Q: What gets logged automatically?
**A:** New patterns and challenges (system decides intelligently)

### Q: Can I use this from Slack?
**A:** Yes! Use `/cc search-solutions "query"`

### Q: Will this slow down builds?
**A:** No! Phase 0 search is < 2 seconds

### Q: What if no solutions are found?
**A:** Normal! That means it's a new pattern. It will be logged after completion.

### Q: How do I see all Sentry solutions?
**A:** `./solution-searcher.sh "sentry"` or `find_by_tags "sentry"`

---

## 📚 Related Documentation

- **GETTING-STARTED.md** - Main startup guide (references KB)
- **KNOWLEDGE-BASE-COMPLETE.md** - Deep dive into KB system
- **SENTRY-N8N-AUTONOMOUS-INTEGRATION-COMPLETE.md** - Example KB entry
- **build-feature.sh** - Code that uses KB (lines 133-174, 187-207, 816-852)

---

## ✅ Summary

### The Knowledge Base is Already Working!

**Automatic Integration:**
- ✅ Referenced in GETTING-STARTED.md
- ✅ Integrated in build-feature.sh (Phase 0)
- ✅ Auto-logs new solutions
- ✅ Available via Slack commands

**You Don't Need To:**
- ❌ Reference it in every prompt
- ❌ Manually search before every build
- ❌ Worry about logging solutions
- ❌ Change any documentation

**Optional But Helpful:**
- 🔍 Manual search when debugging
- 📊 Check stats to see growth
- 💡 Read Phase 0 insights when they appear

**The system learns automatically. Just build features normally!** 🚀

---

## 🎯 Next Steps

1. **Nothing!** The KB is already working
2. **(Optional)** Check current stats: `./view-solutions.sh stats`
3. **(Optional)** Search for Sentry: `./solution-searcher.sh "sentry"`
4. **Keep building** - The KB gets smarter automatically!

Every build you do makes the next one faster! 🧠
