# Prompt Evaluation Results

Initial manual evaluation of the v1 AnswerService prompt. The prompt positions the LLM as a Level 2 Magic: The Gathering Judge, instructs it to assess whether retrieved rules are sufficient before answering, and returns structured JSON with a `confidence` field.

---

## Questions Tested

### 1. How do I win a game of Magic: The Gathering?
**Confidence:** insufficient ⚠️

**Issue — Retrieval too thin:** The vector search returned rule 104.2 ("There are several ways to win the game.") without retrieving any of the subsections that actually enumerate those ways (e.g. 104.2a–104.2f). The LLM correctly declined to answer rather than hallucinate, which means the prompt is working as intended — but the retrieval is failing to surface the relevant rules. This question should return a sufficient answer once retrieval is improved.

---

### 2. What happens when a creature with deathtouch deals combat damage?
**Confidence:** sufficient ✅

Retrieved rules 702.2b, 702.2c, and 704.5h cleanly grounded the answer. Inline citations were accurate and the answer was concise.

---

### 3. How does a player lose the game when their life total reaches zero?
**Confidence:** sufficient ✅

Strong retrieval — rules 704.5a, 119.6, and 104.3b all directly support the answer. Minor note: 810.8c (Two-Headed Giant variant) and 701.12c (life total exchange) were retrieved but weren't relevant to the question. The judge correctly ignored them.

---

### 4. What is the minimum deck size in constructed play?
**Confidence:** sufficient ✅

Rule 100.2a (constructed minimum: 60 cards) was the top result and directly answered the question. The retrieval also surfaced Limited (100.2b) and Commander (903.5a, 903.12d) deck size rules as context. The judge correctly scoped the answer to constructed play only.

---

### 5. How does trample work when blocking creatures have different toughness?
**Confidence:** sufficient ⚠️

**Issue — Retrieval gap + out-of-context citation:** The LLM cited rule 510.1 ("lethal damage is damage equal to a creature's toughness") inline in the answer, but that rule was not present in the retrieved set. The judge drew on general knowledge rather than staying grounded in the provided rules, which violates the prompt's instructions. Additionally, rule 702.19b — which directly describes how a trample creature assigns damage across multiple blockers — was not retrieved at all, leaving a gap in the rules context for this specific question. Both the retrieval and the model's adherence to the grounding instruction need attention here.

---

### 6. What does it mean to destroy a creature?
**Confidence:** sufficient ⚠️

**Issue — Out-of-context citation:** The answer cites rule 704 inline, but rule 704 was not in the retrieved set. The LLM appears to have picked it up from "See rule 704" cross-references embedded in the text of other retrieved rules (302.7, 120.5, 702.2b, 120.6) and then cited it as if it were a retrieved rule. Rule 120.5 was retrieved and correctly cited. The core answer is accurate, but this is the same grounding problem seen in question 5 — the LLM is leaking citations from cross-references rather than staying strictly within the provided rules.

---

### 7. When does a triggered ability go on the stack?
**Confidence:** sufficient ⚠️

**Issue — Out-of-context citation:** The answer cites rule 117.5 inline, but it was not in the retrieved set. Rule 117.2a (which was retrieved) contains "See rule 117.5" in its text, and the LLM followed that cross-reference and cited it directly — the same pattern seen in questions 5 and 6.

**Answer (saved for accuracy review):**
> A triggered ability goes on the stack when the active player receives priority after it has triggered but hasn't been placed on the stack yet. Specifically, each time a player would receive priority, any triggered abilities that have triggered but haven't been put on the stack are then placed on the stack (rule 117.2a, 117.5). Additionally, if it's the upkeep step, any abilities that triggered during the untap step and those that triggered at the start of the upkeep are put on the stack before the active player gets priority (rule 503.1a).

---

## Summary

| Question | Confidence | Notes |
|----------|------------|-------|
| How do I win the game? | insufficient | ⚠️ Retrieval too thin — win condition subsections not returned |
| Deathtouch combat damage | sufficient | ✅ Clean retrieval and accurate answer |
| Life total reaches zero | sufficient | ✅ Strong retrieval, minor irrelevant rules in results |
| Minimum deck size (constructed) | sufficient | ✅ Correct answer, well-grounded |
| Trample with multiple blockers | sufficient | ⚠️ LLM cited rule not in retrieved set; 702.19b missing from retrieval |
| What does it mean to destroy a creature? | sufficient | ⚠️ Cited rule 704 which was not retrieved — leaked from cross-references |
| When does a triggered ability go on the stack? | sufficient | ⚠️ Cited rule 117.5 which was not retrieved — leaked from cross-references. Answer saved for accuracy review. |

## Next Steps

- Investigate why 104.2 subsections aren't being retrieved for the "win the game" question
- Investigate why 702.19b isn't ranking higher for trample questions
- Strengthen prompt grounding instruction — the LLM is repeatedly citing rules it found via cross-references ("See rule 704") inside retrieved text, rather than limiting citations strictly to the provided rule sections. This is now a recurring pattern across questions 5 and 6.
