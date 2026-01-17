# Beeper Developer Community Analysis
> Generated: 2026-01-16
> Source: Chat history from Sep 16, 2025 → Jan 16, 2026
> Rob's first message: Sep 16, 2025 - "API doesn't seem to expose all my messages and actually Beeper itself seems to strugle to fetch them all"

---

## Projects & Tools People Are Building

### Active Projects
1. **beepex** - Chat export tool by John Burnett
   - GitHub: https://github.com/johnburnett/beepex
   - Python-based, uses beeper-desktop-api
   - Detailed bug reports contributed to API improvements

2. **beepcli** - CLI by jlibert with SKILL.md for agent integration
   - GitHub: https://github.com/blqke/beepcli

3. **emaildawg** - Email bridge by rob (read-only currently)
   - GitHub: https://github.com/iFixRobots/emaildawg
   - Community wants write/send capability

4. **AI CRM with Beeper** - personalcoding building CRM for Instagram

5. **memory.store** - a3fckx's AI memory intelligence project
   - Website: https://memory.store/
   - Blog: https://shubhamattri.com/blog/memory-store/
   - Implements episodic, semantic, implicit, prospective memory
   - Works across Claude, ChatGPT, Cursor, Slack, Linear, Beeper, Obsidian

6. **Lightweight Polling Daemon** - Rishi's C program
   - Gist: https://gist.github.com/notnotrishi/0f2c92f48f55c19c7feb6b81f767b634
   - Less than 1MB memory usage
   - Listens to hooks on new/unread messages

7. **Beeper Bricks Game** - Rishi's gaming experiment
   - Gist: https://gist.github.com/notnotrishi/47dbe8088a614effec71e6a22a7af0ab
   - Turned Beeper into a gaming console (demo: bricks game)
   - Possibly releasing VS Code extension

8. **clawdbot** - dreetje's AI bot
   - Listens to group chats and responds
   - Running on Mac mini server

9. **Poke Integration** - Adrien's setup
   - Reads Beeper messages every 15 minutes
   - Can trigger Zapier actions

10. **beeper-automations** - ErdemGKSL
    - GitHub: https://github.com/ErdemGKSL/beeper-automations

11. **beeper-teams-bridge** - Martin Pohl
    - GitHub: https://github.com/martinp0/beeper-teams-bridge
    - Microsoft Teams bridge

12. **beeper-desktop-api** - Rust crate
    - Crates.io: https://crates.io/crates/beeper-desktop-api

13. **n8n + Gemini Workflow** - jasonryer
    - Grabs all chat messages every 24 hours
    - AI drafts replies where appropriate
    - Human reviews before sending

14. **gomuks** - For bot development
    - GitHub: https://github.com/gomuks/gomuks
    - Recommended for building bots

15. **beeper-go-sdk** - Cam's Go SDK
    - GitHub: https://github.com/cameronaaron/beeper-go-sdk

16. **FastMCP + Cloudflare Tunnel** - Rishi's remote MCP access
    - Exposed Beeper MCP server via Cloudflare Tunnel
    - Used FastMCP SDK to let Gemini (or others) call Beeper tools remotely

17. **tasklet.ai Integration** - ishitajindal
    - Automates Granola scripts sent to Claude
    - Auto-uploads transcript data into CRM

18. **Poke AI Use Cases** - Adrien's comprehensive setup
    - Goes through transactions → asks which to add to Splitwise groups
    - Monitors group chats → alerts for interesting/actionable content
    - Extracts events from group chats → adds to calendar
    - "Used like IFTTT/Zapier in the past"

---

## Feature Requests & Implementation Ideas

### MCP/API Improvements
| Feature | Status | Notes |
|---------|--------|-------|
| Attachments API | ✅ Landed | Pushed Jan 11 to nightly |
| Editing support | 🔄 Planned | "Not hard to add" - batuhan |
| Mark as read | ❌ Missing | Requested by Storm1er |
| Chat labels | 🔄 Coming | Available on mobile, coming to desktop |
| Message replies/linked_message_id | ❌ Missing | Exists internally (Cmd+J shows it) but not in API |
| Webhooks | 🔜 Planned | "#1 request" - Will enable instant integrations |
| Hosted API (not on-device) | ❌ Unlikely | "Impossible without big architecture changes" - E2EE |
| MCP without app open | ❌ Unlikely | "Impossible without big architecture changes" |
| Headless Desktop | 🔄 In Progress | "Working on headless/hostable version with decryption/webhooks" |
| Full participant list | 🔄 Coming | Currently limited to 5 in list endpoint |
| Create new chats | ✅ Landed | Use contacts search → create chat → send message |
| Quick replies | ⏳ Long-term | "Don't expect it too soon" |
| Apple/Siri integrations | 🔄 Planned | "Few apple/ai/siri-related things on the roadmap" |
| Optional cloud sync | ⏳ Long-term | "Not on short term roadmap" - backup to Beeper cloud |

### Bridge Requests
- TikTok Chat bridge (Anniqa)
- Discord on-device (erdemdev) - Current cloud bridge causes bans
- LINE bridge - bounty available
- Steam bridge - bounty available
- Dating apps (Bumble, Tinder, Hinge) - humorous request

### Integration Requests
- Zapier two-way integration (pendolino)
- n8n AI Agent connection (maximedde)
- Raycast MCP integration
- VS Code extension (Rishi working on)

### UI/UX Requests
- Custom notification sounds on iOS
- Auto restart on update for nightly
- Obscure messages should blur reactions
- "Shared via Beeper" toggle
- Referral program (batuhan: "if your friend buys Beeper Plus you get a month free" possible)

---

## Known Bugs & API Issues

### John Burnett's Detailed Reports
1. `Message.sort_key` sorting out of order according to timestamp
2. Beeper client version checking endpoint deprecated (`/oauth/userinfo` gone on v1)
3. Contact name resolution inconsistencies (middle names included/excluded)
4. Chat titles showing user's own name instead of other person's
5. `network` vs `accountID` deprecation confusion
6. Duplicate messages needing explicit filtering (94k messages → 21k unique in one chat!)
7. Attachment handling (srcURL vs id) needs documentation
8. Messages with no text/attachments (just metadata)
9. Participant IDs don't match across contexts (e.g., `@signal_xxx:beeper.local` vs `@user:beeper.com`)
10. Self not included in participant list (bug filed)

### Other Reported Issues
- `/v1/accounts` not returning self-hosted iMessage and Discord (Rick)
- LinkedIn not showing all conversations
- Telegram limited to 200-300 messages (need to scroll in client)
- WhatsApp local bridge disconnects 3 seconds on app open
- MCP "Starting..." gets stuck (tylerweitzman)
- Slack group tags (@product, @engg) not showing (ishitajindal)
- Media folder can grow 30GB+ - no easy cleanup (personalcoding)
- Android app gets laggy over time - requires data wipe to fix
- Android attachments in unencrypted chats showing local file paths (bug fixed, won't retroactively fix)

### Discord Bridge Issues (CRITICAL)
- **Using Beeper Discord bridge can get you banned**
- Triggers: Sending DMs to non-friends, sending images
- After 5 "limited" warnings, Discord permanently bans
- keith, Highest, chris all experienced this
- Appeal via Discord support (takes ~2 days)
- Recommendation: Don't use Discord bridge until resolved

---

## Key Resources

| Resource | URL/Info |
|----------|----------|
| Bug Bounty Program | https://hackerone.com/automattic |
| Bridge Bounties | https://blog.beeper.com/2025/10/28/build-a-beeper-bridge/ |
| Feature Support Doc | https://beeper.notion.site/a96db72c53db4a9883e1775bcb61bb80 |
| Nightly Builds | https://www.beeper.com/download/nightly |
| Support Email | help@beeper.com |
| MCP Endpoint | localhost:23373/v0/mcp |
| Open Source Page | https://developers.beeper.com/open-source |
| Remote Access Docs | https://developers.beeper.com/desktop-api/advanced/remote-access/cloudflare |
| Matrix Join Shortcut | Cmd/Ctrl+J → type "matrix" |
| Matrix Email Bridge | https://matrix.org/ecosystem/bridges/email/ |
| birdy.chat WhatsApp interop | https://www.birdy.chat/blog/first-to-interoperate-with-whatsapp |
| Beeper Deep Links Gist | https://gist.github.com/0xdevalias/3d2f5a861335cc1277b21a29d1285cfe |
| Themes Repo | https://github.com/beeper/themes |
| Self-Hosting Bridges | https://developers.beeper.com/bridges/self-hosting |
| JS SDK Changelog | https://github.com/beeper/desktop-api-js/releases |
| Poke AI Agent | https://poke.com |
| Matrix Client-Server Spec | https://spec.matrix.org/v1.16/client-server-api/ |
| Automattic Open Source Creed | https://automattic.com/creed/ |
| Platform SDK (deprecated) | https://github.com/TextsHQ/platform-sdk |

---

## n8n Integration Guide

### Setup Challenges
- **Docker networking**: If n8n runs in Docker on a different machine, need reverse proxy
- **API bound to loopback**: `[::1]:23373` - not accessible from other machines directly
- **Solution**: nginx reverse proxy + firewall exception, or run n8n natively via npm

### Working Configuration (Robert's approach)
```
# nginx reverse proxy config needed for LAN access
# n8n running locally on different machine than Beeper
# Token auth management required
```

### jasonryer's Workflow Pattern
1. n8n grabs all chat messages every 24 hours
2. Saves relevant data as file
3. Gemini Gem processes file with instructions
4. Surfaces relevant info, drafts replies
5. Human reviews and edits before sending

### Key Tips
- Filter message list: `msg.type == "message"` AND `msg.text not None`
- List endpoint returns ALL events (reactions, read receipts, edits) - filter carefully
- anastasiabelenkii: "Docker networking issue... Working swimmingly after fix!"

---

## Architecture & Strategy Notes

### Current Direction
- **Future = On-Device Connections** (Cloud bridges still supported for now)
- **Self-hosted bridges** expected to remain supported indefinitely
- Cloud and On-Device run on the same codebase
- More resources being allocated to Desktop API/MCP (Jan 12)
- Beeper is **no longer an Element fork** (changed last year)

### Technical Details
- **BEEPER_PROFILE** env variable for running multiple instances
- **Cloudflare tunnel** for remote access to Desktop API
- Mobile apps: **Native Swift (iOS)**, **Native Kotlin (Android)**
- SDK is "just typed sugar on top of REST API with no real business logic"
- Message listing goes to phone to fetch older messages
- Chat IDs for **on-device**: encrypted with user's key
- Chat IDs for **cloud**: may include PII (phone numbers, usernames)

### Account Tiers
- **Beeper Plus Plus** = unlimited on-device accounts
- Self-hosting bypasses account limits

### Corporate
- **Automattic** acquired Beeper in April 2024
- Eric (founder) still mentioned fondly (Pebble connection)
- batuhan = "chief of staff at Beeper, main engineer behind developer offerings"

---

## Platform-Specific Notes

### iMessage
- **iMessage integration is NOT a bridge** - it's part of Beeper Desktop app itself
- Not accessible any other way (no headless, no API-only)
- BlueBubbles bridge is separate/self-hosted alternative
- **API quirks**:
  - `get_accounts` may not list iMessage account, but `search_chats` still works
  - Thread titles may return just phone numbers, not contact names
  - Running MCP on different device than iMessage bridge may cause issues
- **Poke + iMessage**: keith confirmed pulling iMessages via Beeper MCP in Oct 2025

### Instagram
- **Self-hosted bridge naming matters**: Use `sh-instagram` NOT `sh-meta` to get correct login flow
- Multiple Instagram accounts need separate bridges with unique appservice IDs
- **Chat title bug**: One-on-one chats may show YOUR name instead of the other person's
- **On-Device is safer**: Unique IP per device vs shared IP with cloud bridge
- Meta cracking down on VPN connections

### WhatsApp
- **Cloud bridge often more stable** than local (barns, Cezar reports)
- Local bridge disconnects for ~3 seconds every time you open the app
- **WhatsApp has device limit** for remote clients - can't have local bridge on every device
- **Media cannot be re-downloaded** for On-Device connections after deletion
- Muting workaround: Mute on WhatsApp app → stays muted in Beeper

### Discord
- **HIGH BAN RISK**: Using Beeper Discord bridge can get you permanently banned
- Triggers: Sending DMs to non-friends, sending images
- After 5 "limited" warnings → permanent ban
- **Recommendation**: Don't use until resolved, or use self-hosted

### Telegram
- Cloud bridge may work better for notifications (messages delivered even when app closed)
- Local bridge: Only receives new messages when app open on phone
- History limited to 200-300 messages (need to scroll in client to load more)

---

## AI Integration Considerations

### Platform Policies
- **Meta banned AI assistants on WhatsApp** (Italy blocked the move)
- Apple may react to unofficial iMessage integrations
- Discord actively bans third-party clients

### Tools Using Unofficial Methods
- **Poke** uses unofficial iMessage methods (ToS risk)
- BlueBubbles bridge for self-hosted iMessage
- AeroChat - another Discord client (same ban risk)

### Recommended Approaches
- Claude Code praised for Beeper integrations
- Sintra AI used for coding/automation
- n8n for workflow automation
- gomuks/maubot for bots

---

## Key Community Members

### Beeper Team
- **batuhan** - Chief of Staff, main engineer for developer offerings, very responsive
- **tulir** - Bridge developer (maunium.net), self-hosted bridges expert
- **Adrien** - Active community member, uses poke

### Active Developers
- **John Burnett** - beepex author, incredibly detailed bug reports, Python SDK pioneer
- **jlibert** - beepcli author
- **Rishi** - Polling daemon, bricks game, VS Code extension, FastMCP/Cloudflare tunnel
- **dreetje** - clawdbot, running Beeper on Mac mini, "my AI sometimes messes up 😝"
- **a3fckx** - memory.store project, "memory is a reconstruction problem"
- **jasonryer** - n8n + Gemini workflow, builds AI-powered automations for businesses
- **bernhardmm** - Building chat categorization/canned responses UI
- **ErdemGKSL** - beeper-automations
- **Martin Pohl** - beeper-teams-bridge
- **Cam** - beeper-go-sdk author
- **Robert** - n8n + nginx reverse proxy pioneer
- **devalias** - Beeper themes/deep links expert, detailed gists, v3→v4 migration docs
- **noeleraphina** - Instagram bridge testing, multi-account setup
- **keith** - Poke + Beeper integration, Discord ban survivor
- **Adrien** - Poke power user, automation workflows, calendar/Splitwise integrations

### Notable Joiners
- **Josef Prusa** - THE Josef Prusa (3D printer fame) joined Dec 31!

---

## API Tips & Tricks

### Authentication & Setup
- **API key location**: Settings > Developers > Approved connections > Click +
- **Gemini CLI setup**: `gemini mcp add --transport http beeper http://localhost:23373/v0/mcp`

### Chat IDs & Querying
- `localChatID` can be used interchangeably with "real" chatID
- `search-chats` uses `type` parameter, not `chatType`
- **Single chatID bug workaround**: API fails with single chatID - duplicate it: `?chatIDs=ID&chatIDs=ID`
- **search_messages limit**: Max 20 results per query (not 50 as you might expect)
- **Create new chat flow**: Search contacts → get participantID → create chat → send message
- WhatsApp participant format: `{number}@s.whatsapp.net` but MUST come from contacts search endpoint

### Network & Remote Access
- API bound to `[::1]:23373` (loopback only)
- For LAN access: use nginx reverse proxy
- Remote access: Cloudflare tunnel (see docs)

### Message Storage
- Messages stored in **SQLite locally**
- "If you saw a message once, it's forever in your local database"
- Matrix API endpoint (`matrix.beeper.com/_matrix/client/v3/rooms/${roomId}/messages`) returns encrypted messages

### Privacy & Read Receipts
- **Incognito Mode** (Beeper Plus): Messages stay unread until you respond (message/reaction) or click "mark as read"
- "Until you respond to a message it's as if it's unread everywhere"

### Cloud vs On-Device Safety
- Cloud connections = one IP shared by all users
- On-device = every device is separate connection (unique IP)
- For Instagram: On-device is safer (you're not sharing IP with others)

### MCP Configuration Formats

**Standard MCP config:**
```json
{
  "mcpServers": {
    "beeper": {
      "httpUrl": "http://localhost:23373/v0/mcp",
      "headers": {
        "Authorization": "Bearer $AUTH"
      }
    }
  }
}
```

**Gemini CLI settings.json:**
```json
{
  "selectedAuthType": "gemini-api-key",
  "mcpServers": {
    "discoveredServer": {
      "httpUrl": "http://localhost:23373/v0/mcp",
      "timeout": 30000
    }
  }
}
```

---

## Debug Tips

### MCP API Debug Script (from Rishi)
```bash
while true; do
  echo "---- $(date) ----"
  curl -I -L http://localhost:23373/v0/spec
  sleep 1
done
```

### MCP Configuration Example
```json
{
  "mcpServers": {
    "beeper": {
      "url": "http://localhost:23373/v0/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_TOKEN_HERE"
      }
    }
  }
}
```

### Attachment URL Handling
```python
# Check URL type before processing
if url.startswith('mxc://') or url.startswith('localmxc://'):
    hydrated_url = client.assets.download(url=url)
else:
    hydrated_url = url  # Already a file path (may be broken Android attachment)
```

**Important notes:**
- `download-asset` only accepts `mxc://` or `localmxc://` URLs
- `beeper-api://` URLs need transformation (check changelog for version requirements)
- **WhatsApp On-Device**: Media CANNOT be re-downloaded after deletion - don't delete!
- Android bug (fixed): Unencrypted chat attachments showed local Android paths like `file:///data/user/0/com.beeper.android/cache/...`

### Duplicate Message Filtering
```python
# Messages can be duplicated - filter by converting to JSON and using set
unique_messages = set([msg.to_json() for msg in messages])
```

### Participant Iteration Pattern
```python
# List endpoint limits to 5 participants, use retrieve for full list
for chat_summary in client.chats.list():
    chat = await client.chats.retrieve(chat_summary.id)
    for p in chat.participants.items:
        print(p.full_name)
```

### Hidden Internal JSON (via Cmd+J)
devalias discovered that `Cmd+J → "Copy selected messages as JSON"` exposes more data than the API:
```json
{
  "message": {
    "linkedMessageID": "900553",  // ← Reply linking! Not in API yet
    "extra": {
      "isE2EE": false,
      "replyThreadID": null,
      "eventID": "$xxlOC4JfFPFSRu2feV20I7OdB-bW6ynWg1K1A0E2LfQ:beeper.local"
    }
  }
}
```

### Empty Messages
Sometimes messages have no text/attachments, just metadata:
```python
{
 'id': '24374',
 'isSender': True,
 'senderID': '@johnburnett:beeper.com',
 'sortKey': '208236',
 'timestamp': '2025-11-06T18:23:56.422Z'
 # No text, no attachments - metadata only
}
```
These are valid - may be read receipts, typing indicators, or other events.

---

## Potential Features to Implement

Based on community needs:

1. **Write capability for emaildawg** - Currently read-only, people want sending
2. **Webhook server** - Since Beeper doesn't have webhooks yet, build a polling-to-webhook bridge
3. **Media cleanup tool** - People have 30GB+ media folders
4. **Chat export enhancements** - Beyond what beepex does
5. **MCP tools for labels** - When API supports it
6. **Message queue with confirmation** - Hayden's suggestion for safer sending
7. **Chat categorization UI** - bernhardmm's use case: categorize messages, suggest canned responses
8. **Daily summary generator** - Like jasonryer's n8n workflow but standalone
9. **Safe Discord bridge** - That doesn't trigger bans
10. **Attachment deduplication** - Handle the duplicate message issue

---

## Timeline Highlights

| Date | Event |
|------|-------|
| Aug 31, 2025 | Early community forming, Cam appreciates MCP handling encryption |
| Sep 5, 2025 | batuhan: "Creating new chats is on the roadmap... sometime next week!" |
| Sep 6, 2025 | Automattic acquisition discussed, n8n integration requests begin |
| Sep 9, 2025 | batuhan: Self-hosted bridges bypass account limits |
| Sep 10, 2025 | Rishi's draftAttachmentPath feature works, requests multiple attachments |
| Sep 11, 2025 | Single chatID bug discovered, workaround: duplicate the ID |
| Sep 12, 2025 | Carlos asks about WhatsApp/GardOps webhook integration |
| **Sep 16, 2025** | **Rob joins community** - first message about API message limitations |
| Sep 16, 2025 | batuhan posts roadmap: unified search, accountIDs[], iMessage support |
| Sep 17, 2025 | Robert gets n8n auto-reply working with nginx reverse proxy |
| Sep 23, 2025 | John Burnett's first message - beginning of beepex project |
| Sep 24, 2025 | devalias asks about webhook/streaming support (now #1 request) |
| Sep 25, 2025 | Rishi exposes Beeper MCP via Cloudflare Tunnel + FastMCP |
| Sep 26, 2025 | batuhan: Attachments "probably Monday or Tuesday" (took longer!) |
| Oct 3, 2025 | noeleraphina self-hosts Instagram bridge, learns `sh-instagram` naming |
| Oct 6, 2025 | batuhan shares Automattic creed/open source philosophy |
| Oct 8, 2025 | Cam releases beeper-go-sdk |
| Oct 23, 2025 | Python SDK available on Beta/Nightly track |
| Nov 7, 2025 | keith: "Discord banned me for using Beeper" |
| Nov 10, 2025 | batuhan: "SDK is just typed sugar on top of REST API" |
| Nov 12, 2025 | Rishi's bricks game demo |
| Nov 13, 2025 | John Burnett's duplicate messages report (94k→21k unique) |
| Nov 17, 2025 | jasonryer shares n8n + Gemini workflow pattern |
| Dec 12, 2025 | batuhan: "I just need webhooks - #1 request by far" |
| Dec 17, 2025 | batuhan: "Working on headless/hostable Desktop API with decryption/webhooks" |
| Dec 26, 2025 | Rishi's debug script for MCP troubleshooting shared |
| Dec 31, 2025 | Josef Prusa joins! 🎉 |
| Jan 4, 2026 | Adrien shares Poke + Zapier workaround (polling every 15m) |
| Jan 9, 2026 | tulir: "Self-hosted bridges expected to remain supported indefinitely" |
| **Jan 11, 2026** | **Attachments API pushed to nightly** 🎉 |
| Jan 12, 2026 | batuhan: "More resources allocated to Desktop API/MCP" |
| Jan 13, 2026 | a3fckx shares memory.store thesis: "Memory is a reconstruction problem" |
| Jan 16, 2026 | personalcoding building "crazy AI CRM stuff with Beeper" for Instagram |
