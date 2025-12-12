# Recommendation Commands

This directory contains commands for managing architecture recommendations - the guardrails and best practices that guide code implementation.

## Purpose

Recommendation commands help teams manage architecture decisions, enable/disable specific recommendations, and track their effectiveness. Recommendations come from architecture reviews, PR feedback, and team decisions.

## Commands

### `/recommendations:disable`
Temporarily disable an architecture recommendation with tracked reason and history. Useful for legacy code migrations or special circumstances.

**Usage:**
```bash
/recommendations:disable <id> --reason "explanation"
/recommendations:disable ARCH-G001 --reason "Legacy migration in progress"
/recommendations:disable ARCH-L001 --until 2025-12-31
```

**Tracking:**
- Reason for disable
- Author and timestamp
- Optional expiration date
- Audit trail

### `/recommendations:enable`
Re-enable a previously disabled architecture recommendation. Updates tracking metadata.

**Usage:**
```bash
/recommendations:enable <id>
/recommendations:enable ARCH-G001
```

### `/recommendations:list`
List all architecture recommendations with filtering options.

**Usage:**
```bash
/recommendations:list
/recommendations:list --status disabled
/recommendations:list --category layer-boundaries
/recommendations:list --confidence high
```

**Filters:**
- Status (active, disabled, all)
- Category (guardrails, hygiene, patterns, layers)
- Confidence level (high, medium, low)
- Source (architecture-review, pr-feedback, manual)

### `/recommendations:stats`
Show recommendation usage statistics, effectiveness metrics, and trends.

**Usage:**
```bash
/recommendations:stats
/recommendations:stats --period 30d
/recommendations:stats --recommendation ARCH-G001
```

**Metrics:**
- Application frequency
- Detection rate
- False positive rate
- Effectiveness rating
- Trend analysis

### `/recommendations:view`
View detailed information about a specific recommendation including examples, rationale, and impact.

**Usage:**
```bash
/recommendations:view <id>
/recommendations:view ARCH-G001
```

**Details:**
- Recommendation text
- Category and confidence
- Examples (good/bad)
- Rationale
- Related recommendations
- Disable history

## Recommendation Categories

Recommendations are organized into categories:

1. **Guardrails** (`ARCH-G-*`) - Hard architectural rules that must not be violated
2. **Hygiene** (`ARCH-H-*`) - Code quality and maintainability practices
3. **Patterns** (`ARCH-P-*`) - Preferred implementation patterns
4. **Layers** (`ARCH-L-*`) - Layer boundary and dependency rules

## When to Disable Recommendations

Disable recommendations temporarily for:
- **Legacy migration** - Moving old code, will fix later (weeks to months)
- **Not applicable** - Recommendation doesn't fit your architecture (permanent)
- **Temporary override** - Special case requires exception (days to weeks)
- **Testing/debugging** - Need to bypass temporarily (hours to days)
- **Compliance conflict** - Legal/audit requirement overrides (until resolved)

Always provide a clear reason when disabling recommendations.

## Integration

Recommendation commands integrate with:
- **Quality** (`/quality:code-review`) - Applies recommendations during review
- **Playbook** (`/playbook:*`) - Recommendations stored in agent playbook
- **Architecture Review** (`/quality:architecture-review`) - Generates recommendations
