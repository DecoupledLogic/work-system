# Recommendation Commands

Manage architecture recommendations (guardrails, hygiene, patterns).

## Commands

| Command | Description |
|---------|-------------|
| `/recommendations:list-recommendations` | List all recommendations |
| `/recommendations:view-recommendation` | View recommendation details |
| `/recommendations:disable-recommendation` | Temporarily disable a recommendation |
| `/recommendations:enable-recommendation` | Re-enable a recommendation |
| `/recommendations:recommendation-stats` | View usage statistics |

## Quick Examples

```bash
# List recommendations
/recommendations:list-recommendations
/recommendations:list-recommendations --status disabled
/recommendations:list-recommendations --category guardrails

# View details
/recommendations:view-recommendation ARCH-G001

# Disable temporarily
/recommendations:disable-recommendation ARCH-G001 --reason "Legacy migration"
/recommendations:disable-recommendation ARCH-L001 --until 2025-12-31

# Re-enable
/recommendations:enable-recommendation ARCH-G001
```

## Recommendation Categories

| Prefix | Category | Description |
|--------|----------|-------------|
| `ARCH-G-*` | Guardrails | Hard rules, must not violate |
| `ARCH-H-*` | Hygiene | Code quality practices |
| `ARCH-P-*` | Patterns | Preferred implementations |
| `ARCH-L-*` | Layers | Layer boundary rules |

See source commands in [commands/recommendations/](../../../commands/recommendations/) for full documentation.
