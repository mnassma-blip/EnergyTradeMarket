# EnergyTradeMarket
Decision Making System for P2P Energy Trading in Energy Market
## What the model does
A NetLogo agent-based model of a peer-to-peer household energy market. Each
household ("prosumer") has hourly solar generation and demand; the model runs
a Stackelberg-game price-adjustment algorithm each hour so households can buy
and sell surplus/deficit energy among themselves (and with the grid), track
battery storage, and log the results.

## Files needed to run it
Everything below must sit in the **same folder** as the `.nlogo` file
(NetLogo resolves relative filenames from the model's own directory).

### 1. Generation profile file required
Loaded in `load-data` at setup.

**Format** (comma-separated):
- Row 1: header row (skipped, content doesn't matter).
- Each following row = one household, with:
  - Column 1: household name (e.g. `2bedroom1`) — this name is reused to find
    that household's demand file (see below), so it must match exactly.
  - Columns 2–25: 24 hourly generation values (one representative day's
    generation profile, hour 1 → hour 24).
- The number of data rows = the number of households (`prosumer`) created.

### 2. Per-household demand file — required, one per household
Loaded in `get-demand-matrix`, filename built automatically as:

```
hourly_average_clone_Dec_<household-name>.csv
```

e.g. for household name `2bedroom1` the model expects
`hourly_average_clone_Dec_2bedroom1.csv` in the model folder. You need one
such file for **every household name** that appears in the generation
profile file.

**Format**:
- Rows = hours (24), each row's first column is a row label (skipped).
- Remaining columns = one column per day of the month; the model selects the
  column for the current simulated day (`day-now`, plus offset 1) to build
  that day's 24-hour demand list.

### 3. Output files — created automatically (not inputs)
If `Save-Results?` is **On**, the model writes/overwrites these CSVs in the
model folder while running: `prosumerresults.csv`,
`buyersellerdailyresults.csv`, `buyersellerhourlyresults.csv`.

## Interface parameters you can set before pressing Setup/Go

| Widget | Type | Meaning |
|---|---|---|
| `Run-New-File?` | switch | Off = load `GenerationProfileFeb.csv`; On = prompt for a file to load instead |
| `Save-Results?` | switch | Whether to write the three results CSVs |
| `Start-Hour` | input (number) | Hour of day the simulation starts at |
| `evolution-threshold-e` | input (number) | Convergence threshold ε for the demand-evolution loop (paper eq. reference) |
| `stackelberg-threshold-e` | input (number) | Convergence threshold ε for the Stackelberg price game (paper eq. 38) — how close buyer ask must get to seller potential before the price loop stops |
| `row-buy` | input (number) | Grid buy price (price a household pays the grid) |
| `row-sell` | input (number) | Grid sell price (price a household is paid by the grid) |
| `Flexible-Demand-Ratio` | slider (0–100%) | Share of demand treated as flexible/shiftable |
| `battery-size` | slider (0–100) | Household battery storage capacity |
| `price-subsidy` | slider (0–0.4) | Subsidy applied on top of trading price |

## How to run
1. Put the `.nlogo` file, `GenerationProfile.csv` (or your own file), and
   every household's `hourly_average_clone_Dec_<household-name>.csv` in the
   same folder.
2. Open the model in NetLogo.
3. Set the switches/inputs/sliders as needed.
4. Click **Setup**, then **Go**.
5. If `Save-Results?` is on, check the output CSVs in the model folder after
   the run.

## Notes / things to double check
- Household names in the generation file must exactly match the
  `<household-name>` used in each demand filename (case- and
  spelling-sensitive).
