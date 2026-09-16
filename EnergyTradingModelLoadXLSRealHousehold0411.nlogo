extensions[gis csv matrix]

globals[
  hs
  num-houses
  hour-now
  day-now
  avg-utility-sigma ;;average net utility
  average-price ;;current hour average price
  current-hour-sell-price-pie-list ;;the price list of all the sellers of current hour in order, not sellers treated as 0

  adjustment-eta1 ;;adjustment in algorithm 1

  current-day-potential-buyers
  current-day-actual-buyers
  current-day-potential-sellers
  current-day-actual-sellers

  current-hour-potential-buyers
  current-hour-actual-buyers
  current-hour-potential-sellers
  current-hour-actual-sellers

  daily-buyer-seller-results
  hourly-buyer-seller-results

  ]

breed [prosumers prosumer]

prosumers-own [
  prosumer-ID
  current-hour-prosumer-type ;;;buyer or seller
  household-name ;;household name, e.g. 2bedroom1
  housetype
  storage-capacity

  demand-matrix ;;current month demand matrix read directly from the input data

  hourly-generation-list ;;24 hours generation list from input table
  hourly-demand-list ;;24 hours demand list from input table

  current-hour-generation ;; current hour generation from generation list
  current-hour-demand ;;current hour demand from demand list
  current-hour-battery-save ;;the unsold energy will be stored in the battery and will be for sell in the next hour
  current-hour-lambda ;;current hour lambda from lambda list
  GDR ;;current hour generation to demand ratio by equation 8
  current-hour-power-for-sell-P ;;current hour power for sell, current hour generation minus current hour demand
  current-hour-SDR ;;current hour supply to demand ratio defined by equation 23
  current-hour-sell-garma  ;;current hour sell garma

  current-hour-utility  ;;current hour utility
  current-hour-net-utility-sigma

  current-hour-flexibledemand  ;;flexible demand
  current-hour-total-demand-X ;;flexible demand plus current hour demand
  current-hour-sell-ask
  current-hour-buy-X-list ;;x to store function 21
  current-hour-actual-sell ;;the actual amount of energy the seller sold
  current-hour-actual-buy ;;the actual amount of engery the buyer by function 21
  current-hour-grid-buy ;;the unmet energy demand will be bought from market
  current-hour-grid-sell ;;the extra energy sold to market
  current-hour-actual-buy-list ;;the actual amount of engery the buyer bought from each prosumer

  current-hour-actual-spend
  current-hour-actual-earn

  current-hour-buyer-W-list
  Current-hour-seller-W
  current-hour-sell-price-pie

  theta

  ;;summary of the results in daily
  current-day-power-for-sell-P
  daily-prosumer-results
  energy-sold-all-day-prosumer ;;energy sold to other prosumers
  energy-sold-all-day-grid ;;energy sold to the grid
  energy-bought-all-day-prosumer ;;energy bought from other prosumers
  energy-bought-all-day-grid ;;energy bought from the grid
  money-spend-all-day-prosumer ;;money spend on other prosumers
  money-spend-all-day-grid ;;money spend on the grid
  money-earn-all-day-prosumer ;;money earn from other prosumers
  money-earn-all-day-grid ;;money earn from the grid
]

To setup
  __clear-all-and-reset-ticks

  set hour-now start-hour
  set day-now 0
  load-data
  set current-hour-sell-price-pie-list n-values num-houses[-> 0]
  update-prosumers-by-hour
  initial-garma

  if Save-Results? = true [
    csv:to-file "prosumerresults.csv" []
    file-open "prosumerresults.csv"
    file-print csv:to-row (list "Current Day" "Prosumer Name"  "Energy for Sell All Day" "Energy Sold All Day to other prosumers" "energy sold all day to grid" "Energy Bought All Day from other prosumers" "energy bought all day from grid" "Money Spend All Day on other prosumers" "money spend all day on grid" "Money Earned All Day from other prosumers" "money earn all day from grid" "Money Balance All Day" "")
    file-flush
    file-close

    csv:to-file "buyersellerdailyresults.csv" []
    file-open "buyersellerdailyresults.csv"
    file-print csv:to-row (list "Current Day" "Potential Buyers" "Potential Sellers" "Actual Buyers" "Actual Sellers" "")
    file-flush
    file-close

    csv:to-file "buyersellerhourlyresults.csv" []
    file-open "buyersellerhourlyresults.csv"
    file-print csv:to-row (list "Current Day" "Current Hour" "Potential Buyers" "Potential Sellers" "Actual Buyers" "Actual Sellers" "")
    file-flush
    file-close
  ]
  reset-ticks
end

to load-data
  ifelse Run-New-File? = true
  [file-open user-file]
  [file-open "GenerationProfileFeb.csv"]
  let r 0
  let house-list []
  let skip-first-row 0
  while [not file-at-end?][
    set house-list csv:from-row file-read-line
;    if skip-first-row > 0 and skip-first-row < 30[
    if skip-first-row > 0 [
      create-prosumer-agents house-list r
      set r r + 1
      set num-houses r]
   set skip-first-row skip-first-row + 1
  ]
  file-close-all
end

to get-demand-matrix
  let fullfilename word (word "hourly_average_clone_Dec_" household-name) ".csv"
  let hour-month csv:from-file fullfilename
  set demand-matrix matrix:from-row-list hour-month
end

to-report load-current-day-demand-data [currentday]
  let current-day-demand remove-item 0 (matrix:get-column demand-matrix (currentday + 1))
  report current-day-demand
  file-close-all
end

to create-prosumer-agents [house-list id]
  let hs-generation-list []
  let hs-name item 0 house-list
  set hs-generation-list lput item 1 house-list hs-generation-list
  set hs-generation-list lput item 2 house-list hs-generation-list
  set hs-generation-list lput item 3 house-list hs-generation-list
  set hs-generation-list lput item 4 house-list hs-generation-list
  set hs-generation-list lput item 5 house-list hs-generation-list
  set hs-generation-list lput item 6 house-list hs-generation-list
  set hs-generation-list lput item 7 house-list hs-generation-list
  set hs-generation-list lput item 8 house-list hs-generation-list
  set hs-generation-list lput item 9 house-list hs-generation-list
  set hs-generation-list lput item 10 house-list hs-generation-list
  set hs-generation-list lput item 11 house-list hs-generation-list
  set hs-generation-list lput item 12 house-list hs-generation-list
  set hs-generation-list lput item 13 house-list hs-generation-list
  set hs-generation-list lput item 14 house-list hs-generation-list
  set hs-generation-list lput item 15 house-list hs-generation-list
  set hs-generation-list lput item 16 house-list hs-generation-list
  set hs-generation-list lput item 17 house-list hs-generation-list
  set hs-generation-list lput item 18 house-list hs-generation-list
  set hs-generation-list lput item 19 house-list hs-generation-list
  set hs-generation-list lput item 20 house-list hs-generation-list
  set hs-generation-list lput item 21 house-list hs-generation-list
  set hs-generation-list lput item 22 house-list hs-generation-list
  set hs-generation-list lput item 23 house-list hs-generation-list
  set hs-generation-list lput item 24 house-list hs-generation-list

  ;;create prosumer agents by shapefile
  ask one-of patches[
    sprout-prosumers 1[
      set prosumer-ID id
      set household-name hs-name
      let lid prosumer-ID
      get-demand-matrix
      ask patch-ahead 0.7[set plabel lid]
      set hourly-generation-list hs-generation-list
      set hourly-demand-list update-current-day-demand
      set current-hour-battery-save 0

      ;;different prosumer different theta, theta is defined as constant in the paper
      set theta 0.02

      set shape "house"
      set color green
      set size 1]]
end

to-report update-current-day-demand
  let hs-list load-current-day-demand-data day-now
  let hs-demand-list []
    set hs-demand-list lput item 0 hs-list hs-demand-list
    set hs-demand-list lput item 1 hs-list hs-demand-list
    set hs-demand-list lput item 2 hs-list hs-demand-list
    set hs-demand-list lput item 3 hs-list hs-demand-list
    set hs-demand-list lput item 4 hs-list hs-demand-list
    set hs-demand-list lput item 5 hs-list hs-demand-list
    set hs-demand-list lput item 6 hs-list hs-demand-list
    set hs-demand-list lput item 7 hs-list hs-demand-list
    set hs-demand-list lput item 8 hs-list hs-demand-list
    set hs-demand-list lput item 9 hs-list hs-demand-list
    set hs-demand-list lput item 10 hs-list hs-demand-list
    set hs-demand-list lput item 11 hs-list hs-demand-list
    set hs-demand-list lput item 12 hs-list hs-demand-list
    set hs-demand-list lput item 13 hs-list hs-demand-list
    set hs-demand-list lput item 14 hs-list hs-demand-list
    set hs-demand-list lput item 15 hs-list hs-demand-list
    set hs-demand-list lput item 16 hs-list hs-demand-list
    set hs-demand-list lput item 17 hs-list hs-demand-list
    set hs-demand-list lput item 18 hs-list hs-demand-list
    set hs-demand-list lput item 19 hs-list hs-demand-list
    set hs-demand-list lput item 20 hs-list hs-demand-list
    set hs-demand-list lput item 21 hs-list hs-demand-list
    set hs-demand-list lput item 22 hs-list hs-demand-list
    set hs-demand-list lput item 23 hs-list hs-demand-list
  report hs-demand-list
end

;;utility function equation 15
to-report utility-function [lambda demand thetaa]
  let utility lambda * demand - 0.5 * thetaa * demand ^ 2
  report utility
end

;;update current hour status and prosumer identify themselves as buyer or seller
to update-prosumers-by-hour
  ask prosumers[

    set current-hour-generation item hour-now hourly-generation-list + current-hour-battery-save
    set current-hour-demand item hour-now hourly-demand-list
    ;;lambda value following equation 15 used to differentiate prosumers, different time different lambda
    set current-hour-lambda 1 ;;the paper 2094 indicates lamdda is random from 5 to 10

    ;;update current hour demand, hourly demand is fix demand plus flexible demand
    let p-ratio 1
    carefully
    [let avg-price precision (mean filter [i -> i > 0] current-hour-sell-price-pie-list) 3
      set p-ratio (row-buy - avg-price + price-subsidy) / (row-buy - row-sell)]
    [set p-ratio 0.1]
    set current-hour-flexibledemand current-hour-demand * (p-ratio * (Flexible-Demand-Ratio / 100)) ;;beta in equation 14
    set current-hour-total-demand-X current-hour-demand + current-hour-flexibledemand

    ;;update current hour utility based on total demand
    set current-hour-utility utility-function current-hour-lambda current-hour-total-demand-X theta

    ;;update prosumer type based on total demand
    if current-hour-generation > current-hour-total-demand-X [
      set current-hour-power-for-sell-P precision (current-hour-generation - current-hour-total-demand-X) 3
      set current-hour-prosumer-type "seller" set color red]
    if current-hour-generation <= current-hour-total-demand-X [
      set current-hour-power-for-sell-P 0
      set current-hour-prosumer-type "buyer" set color yellow]

    set current-hour-actual-buy 0
    set current-hour-actual-buy-list n-values num-houses[-> 0]
    set current-hour-actual-spend 0
    set current-hour-actual-sell 0
    set current-hour-actual-earn 0
    set current-hour-grid-sell 0
    set current-hour-grid-buy 0
    set current-hour-net-utility-sigma 0
  ]
end


;;noncooperative game among sellers
to update-seller-welfare-function
  ;;update sellers
  ask prosumers[
    let total-demand-to-seller-S 0
    let cid prosumer-ID
    ask prosumers[
      let garma current-hour-sell-garma
      ifelse current-hour-prosumer-type = "buyer"
      [set total-demand-to-seller-S total-demand-to-seller-S + garma * (item cid current-hour-actual-buy-list)]
      [set total-demand-to-seller-S 0]]

    ifelse current-hour-power-for-sell-P > total-demand-to-seller-S
    [set current-hour-seller-W  current-hour-utility + current-hour-sell-price-pie * total-demand-to-seller-S]
    [set current-hour-seller-W  current-hour-utility + current-hour-sell-price-pie * min (list current-hour-power-for-sell-P total-demand-to-seller-S)]
  ]
end


;;welfare function 19
to-report max-W-evaluation [lambda ctheta generation buy-x pie]
  let evaluation (buy-x + generation) * lambda - 0.5 * ctheta * (buy-x + generation) ^ 2 - pie * buy-x
  report evaluation
end


to go

  update-prosumers-by-hour

  if (count prosumers with [current-hour-prosumer-type = "buyer"]) > 0 and (count prosumers with [current-hour-prosumer-type = "seller"]) > 0[
    stackelberg-game-buyers-sellers]

  current-hour-final-buy-sell

  ifelse hour-now >= 23
  [set day-now day-now + 1
    ;;record 24 hours record
    out-put-to-window
    if Save-Results? = true[
      daily-prosumer-results-output
      buyer-seller-daily-results-output]
    ask prosumers [
      set hourly-demand-list update-current-day-demand ;;demand of each day of the month
      set current-day-power-for-sell-P 0
      set energy-sold-all-day-prosumer 0
      set energy-sold-all-day-grid 0
      set energy-bought-all-day-prosumer 0
      set energy-bought-all-day-grid 0
      set money-spend-all-day-prosumer 0
      set money-spend-all-day-grid 0
      set money-earn-all-day-prosumer 0
      set money-earn-all-day-grid 0]

      set current-day-potential-buyers ""
      set current-day-actual-buyers ""
      set current-day-potential-sellers ""
      set current-day-actual-sellers ""
  ]
  [ask prosumers[
    let pid prosumer-ID
    set energy-bought-all-day-prosumer energy-bought-all-day-prosumer + current-hour-actual-buy
    set energy-bought-all-day-grid energy-bought-all-day-grid + current-hour-grid-buy

    set money-spend-all-day-prosumer money-spend-all-day-prosumer + current-hour-actual-spend
    set money-spend-all-day-grid money-spend-all-day-grid + current-hour-grid-buy * row-buy

    if current-hour-generation - current-hour-total-demand-X > 0[
      set current-day-power-for-sell-P current-day-power-for-sell-P + current-hour-generation - current-hour-total-demand-X]

    set energy-sold-all-day-prosumer energy-sold-all-day-prosumer + current-hour-actual-sell
    set energy-sold-all-day-grid energy-sold-all-day-grid + current-hour-grid-sell

    set money-earn-all-day-prosumer money-earn-all-day-prosumer + current-hour-actual-earn
    set money-earn-all-day-grid money-earn-all-day-grid + current-hour-grid-sell * row-sell
    ]
    set current-day-potential-sellers sentence current-day-potential-sellers (count prosumers with [current-hour-prosumer-type = "seller"])
    set current-day-potential-buyers sentence current-day-potential-buyers (count prosumers with [current-hour-prosumer-type = "buyer"])
    set current-day-actual-sellers sentence current-day-actual-sellers (count prosumers with [current-hour-actual-sell > 0 ])
    set current-day-actual-buyers sentence current-day-actual-buyers (count prosumers with [current-hour-actual-buy > 0 ])
  ]

  set current-hour-potential-sellers  (count prosumers with [current-hour-prosumer-type = "seller"])
  set current-hour-potential-buyers (count prosumers with [current-hour-prosumer-type = "buyer"])
  set current-hour-actual-sellers  (count prosumers with [current-hour-actual-sell > 0 ])
  set current-hour-actual-buyers (count prosumers with [current-hour-actual-buy > 0 ])

 buyer-seller-hourly-results-output

  set hour-now (hour-now + 1) mod 24
  if day-now + 1 = 31 [stop]

  tick
end

;;maximizing welfare equation 21
to-report argmax [current-lambda c-theta current-demand current-generation flexible current-pie]
  let max-argument 0
  let max-x current-demand - current-generation + flexible
  let min-x current-demand - current-generation
  set max-argument (current-lambda + current-generation - c-theta * current-generation - current-pie) / (2 * c-theta)
  if max-argument > max-x [set max-argument max-x]
  if max-argument < min-x [set max-argument min-x]
  report max-argument
end

;;the sum of garm equals 1
to initial-garma
  let nm sum [current-hour-power-for-sell-P ] of prosumers with [current-hour-prosumer-type = "seller"]
  ifelse nm > 0 [
    ;;the garma starts from equal
    ask prosumers [
      ifelse current-hour-prosumer-type = "seller"
      [set current-hour-sell-garma  (current-hour-power-for-sell-P / nm) ]
      [set current-hour-sell-garma 0]]]
  [ask prosumers[set current-hour-sell-garma 0]]
end

to update-buy-based-on-price
  initial-garma ;;randomly set initial garma

  ask prosumers[
    set current-hour-buy-X-list n-values num-houses[-> 0]
    set current-hour-actual-buy-list current-hour-buy-X-list
  ]

  ask prosumers with [current-hour-prosumer-type = "buyer"][
    let pid prosumer-id
    let minx current-hour-demand
    let maxx current-hour-total-demand-X
    let between-min-max n-values 10 [i -> i]

    ;;create initial gama list and the sum of gama equals 1
    let itemx 0

    foreach current-hour-buy-X-list[x ->
      let prosumertype ""
      let current-lambda 0
      ask prosumers with [prosumer-id = itemx][
        set current-lambda current-hour-lambda
        set prosumertype current-hour-prosumer-type]
      ifelse prosumertype = "seller"
      [let max-buy-now-X argmax current-lambda theta current-hour-demand current-hour-generation current-hour-flexibledemand (item itemx current-hour-sell-price-pie-list)
        set current-hour-buy-X-list replace-item itemx current-hour-buy-X-list (precision max-buy-now-X 3)]
      [set current-hour-buy-X-list replace-item itemx current-hour-buy-X-list 0 ]
      set itemx itemx + 1]
  ]
end

;;evolutionary game among buyers
to evolutionary-game-buyers
  update-buy-based-on-price

  let num-loop 0
;  set-current-plot "Convergence of Evolutionary Game"
;  clear-plot
  loop[
    ask prosumers with [current-hour-prosumer-type = "seller"][
      let pid prosumer-id
  ;        let current-garma current-hour-sell-garma
      let ttbuy 0
      let garma current-hour-sell-garma
      ask prosumers with [current-hour-prosumer-type = "buyer"][
        set ttbuy ttbuy + garma * (item pid current-hour-buy-X-list)]
        ;;equation 22
      set current-hour-sell-ask (precision ttbuy 3)
    ]

    ask prosumers with [current-hour-prosumer-type = "seller"][
      let pid prosumer-id
      let sellergarma current-hour-sell-garma
      ;;equation 25 and 26
      let square-sum 0
      ifelse current-hour-power-for-sell-P >= current-hour-sell-ask
      [ask prosumers with [current-hour-prosumer-type = "buyer"][
        set current-hour-actual-buy-list replace-item pid current-hour-actual-buy-list ((item pid current-hour-buy-X-list ) * sellergarma)
        set square-sum square-sum + 0.5 * theta * (item pid current-hour-buy-X-list) ^ 2 + (current-hour-lambda - 0.5 * theta * current-hour-generation) * current-hour-generation]
        ]
      [let sdr 0
       ;;equation 23
        ifelse current-hour-sell-ask > 0 [set sdr precision (current-hour-power-for-sell-P / current-hour-sell-ask) 3][set sdr 0]
        ask prosumers with [current-hour-prosumer-type = "buyer"][
          set current-hour-actual-buy-list replace-item pid current-hour-actual-buy-list ((item pid current-hour-buy-X-list ) * sellergarma * sdr)
          set square-sum square-sum + (sdr * (1 - 0.5 * sdr)) * (theta * (item pid current-hour-actual-buy-list) ^ 2 + (current-hour-lambda - 0.5 * theta * current-hour-generation) * current-hour-generation)]
        ]
      set current-hour-net-utility-sigma (precision square-sum 3)
    ]

    ;;average utility sigma
    set avg-utility-sigma 0
    ask prosumers with [current-hour-prosumer-type = "seller"] [set avg-utility-sigma avg-utility-sigma + (current-hour-sell-garma * current-hour-net-utility-sigma)]

;    ;;observe the convergence of evolutionary game
;    set-current-plot "Convergence of Evolutionary Game"

    let adjustment max[abs(current-hour-net-utility-sigma - avg-utility-sigma)] of prosumers with [current-hour-prosumer-type = "seller"]
;    plotxy num-loop adjustment

  if adjustment != 0 [set adjustment-eta1 precision (1 / adjustment) 3]
  set num-loop num-loop + 1
  ifelse adjustment < evolution-threshold-e or num-loop > 30
  [stop]
  [ask prosumers[
      ifelse current-hour-prosumer-type = "seller"
      [set current-hour-sell-garma current-hour-sell-garma + adjustment-eta1 * current-hour-sell-garma * (current-hour-net-utility-sigma - avg-utility-sigma)
        if current-hour-sell-garma <= 0[set current-hour-sell-garma 0]]
      [set current-hour-sell-garma 0]]]
    let test int(sum [current-hour-sell-garma] of prosumers with [current-hour-prosumer-type = "seller"])
    if test != 1  and test != 0 [
      show "something wrong"
      show int(sum [current-hour-sell-garma] of prosumers with [current-hour-prosumer-type = "seller"])]
    ]
end

to current-hour-final-buy-sell
  ask prosumers with [current-hour-prosumer-type = "buyer"][
    let pid prosumer-id
    ifelse current-hour-actual-buy-list = 0
      [set current-hour-actual-buy 0
        set current-hour-actual-spend 0 ]
      [set current-hour-actual-buy sum current-hour-actual-buy-list
        ;;the energy price bought from grid will be equals the row-buy
        set current-hour-actual-spend sum (map * current-hour-sell-price-pie-list current-hour-actual-buy-list) - price-subsidy * current-hour-actual-buy]

      set current-hour-grid-buy current-hour-total-demand-X - current-hour-actual-buy - current-hour-generation
      set current-hour-actual-sell 0
      set current-hour-battery-save 0 ;;the energy saved in the battery was used
      if current-hour-grid-buy < 0 [show current-hour-grid-buy set current-hour-grid-buy 0 show "one negative buyer here"  ]]


  ask prosumers with [current-hour-prosumer-type = "seller"][

    let pid prosumer-id
    set current-hour-actual-sell sum [item pid current-hour-actual-buy-list] of prosumers with [current-hour-actual-buy-list != 0]
      set current-hour-battery-save current-hour-generation - current-hour-actual-sell - current-hour-total-demand-X
      ;;store the extra energy to battery
      if current-hour-battery-save > battery-size
      [set current-hour-grid-sell current-hour-battery-save - battery-size
        set current-hour-battery-save battery-size]
      set current-hour-actual-buy 0
      set current-hour-actual-spend 0
      set current-hour-actual-earn current-hour-actual-sell * current-hour-sell-price-pie ;;the energy sold to the grid will be the cost price row-sell
    ]

;  ask prosumers [
;  let pid prosumer-id
;  ifelse current-hour-prosumer-type = "buyer"
;    [ifelse current-hour-actual-buy-list = 0
;      [set current-hour-actual-buy 0
;        set current-hour-actual-spend 0 ]
;      [set current-hour-actual-buy sum current-hour-actual-buy-list
;        ;;the energy price bought from grid will be equals the row-buy
;        set current-hour-actual-spend sum (map * current-hour-sell-price-pie-list current-hour-actual-buy-list) - price-subsidy * current-hour-actual-buy]
;
;      set current-hour-grid-buy current-hour-total-demand-X - current-hour-actual-buy - current-hour-generation
;      set current-hour-actual-sell 0
;      set current-hour-battery-save 0 ;;the energy saved in the battery was used
;      if current-hour-grid-buy < 0 [set current-hour-grid-buy 0 show "one negative buyer here"]]
;  [set current-hour-actual-sell sum [item pid current-hour-actual-buy-list] of prosumers with [current-hour-actual-buy-list != 0]
;      set current-hour-battery-save current-hour-generation - current-hour-actual-sell - current-hour-total-demand-X
;      ;;store the extra energy to battery
;      if current-hour-battery-save > battery-size
;      [set current-hour-grid-sell current-hour-battery-save - battery-size
;        set current-hour-battery-save battery-size]
;      set current-hour-actual-buy 0
;      set current-hour-actual-spend 0
;      set current-hour-actual-earn current-hour-actual-sell * current-hour-sell-price-pie ;;the energy sold to the grid will be the cost price row-sell
;    ]
;  ]

;  show sum[current-hour-actual-buy] of prosumers - sum [current-hour-actual-sell] of prosumers
end

;;stackelberg game between sellers and buyers
to stackelberg-game-buyers-sellers
  let maxgap 0
  ;;set initial price pie
  ask prosumers[
    ifelse current-hour-prosumer-type = "seller"[
      set current-hour-sell-price-pie 0.3 * random-float (row-buy - row-sell) + row-sell
      set current-hour-sell-price-pie precision current-hour-sell-price-pie 3]
    [set current-hour-sell-price-pie 0]]

    let num-loop 0
    loop [
    update-sell-price-list
    evolutionary-game-buyers

    set maxgap (max [abs(current-hour-sell-ask - current-hour-power-for-sell-P)] of prosumers with [current-hour-prosumer-type = "seller"])
    set num-loop num-loop + 1
    ifelse maxgap < stackelberg-threshold-e  or num-loop > 50
    [stop]
    [let adjustment-eta2 (1 / maxgap)
      ask prosumers[
      let new-price current-hour-sell-price-pie * (1 + adjustment-eta2 * (current-hour-sell-ask - current-hour-power-for-sell-P))
      if new-price <= row-buy and new-price >= row-sell
      [set current-hour-sell-price-pie precision new-price 3]]
    ]
  ]

end

to update-sell-price-list
  set current-hour-sell-price-pie-list []
  foreach sort-on [prosumer-ID] prosumers[
      the-prosumer ->
      ask the-prosumer[ set current-hour-sell-price-pie-list lput current-hour-sell-price-pie current-hour-sell-price-pie-list ]]
end

to daily-prosumer-results-output
  file-open "prosumerresults.csv"
  ask prosumers[
    set daily-prosumer-results []
    set daily-prosumer-results lput day-now daily-prosumer-results
    set daily-prosumer-results lput household-name daily-prosumer-results
    set daily-prosumer-results lput (precision current-day-power-for-sell-P 3) daily-prosumer-results

    set daily-prosumer-results lput (precision energy-sold-all-day-prosumer 3)  daily-prosumer-results  ;;enery sold to other prosumers
    set daily-prosumer-results lput (precision energy-sold-all-day-grid 3)  daily-prosumer-results  ;;enery sold to grid

    set daily-prosumer-results lput (precision energy-bought-all-day-prosumer 3) daily-prosumer-results  ;;energy bought from other prosumers
    set daily-prosumer-results lput (precision energy-bought-all-day-grid 3) daily-prosumer-results  ;;energy bought from grid

    set daily-prosumer-results lput (precision money-spend-all-day-prosumer 3)  daily-prosumer-results  ;;money spend on other prosuemrs
    set daily-prosumer-results lput (precision money-spend-all-day-grid 3)  daily-prosumer-results  ;;money spend on the grid

    set daily-prosumer-results lput (precision money-earn-all-day-prosumer 3)  daily-prosumer-results  ;;money spend on other prosumers
    set daily-prosumer-results lput (precision money-earn-all-day-grid 3)  daily-prosumer-results  ;;money spend on the grid

    set daily-prosumer-results lput (precision (- money-spend-all-day-prosumer - money-spend-all-day-grid + money-earn-all-day-prosumer + money-earn-all-day-grid) 3) daily-prosumer-results   ;;money balance\

    file-print csv:to-row daily-prosumer-results
;    set daily-prosumer-results lput sum (hourly-demand-list) daily-prosumer-results
;    set daily-prosumer-results lput sum (hourly-generation-list) daily-prosumer-results
  ]
    file-flush
    file-close
end

to buyer-seller-daily-results-output
  file-open "buyersellerdailyresults.csv"
  set daily-buyer-seller-results []
  set daily-buyer-seller-results lput day-now daily-buyer-seller-results

  set daily-buyer-seller-results lput current-day-potential-buyers daily-buyer-seller-results
  set daily-buyer-seller-results lput current-day-potential-sellers daily-buyer-seller-results
  set daily-buyer-seller-results lput current-day-actual-buyers daily-buyer-seller-results
  set daily-buyer-seller-results lput current-day-actual-sellers daily-buyer-seller-results

  file-print csv:to-row daily-buyer-seller-results
;    set daily-prosumer-results lput sum (hourly-demand-list) daily-prosumer-results
;    set daily-prosumer-results lput sum (hourly-generation-list) daily-prosumer-results
    file-flush
    file-close
end


to buyer-seller-hourly-results-output
  file-open "buyersellerhourlyresults.csv"
  set hourly-buyer-seller-results []
  set hourly-buyer-seller-results lput day-now hourly-buyer-seller-results
  set hourly-buyer-seller-results lput hour-now hourly-buyer-seller-results

  set hourly-buyer-seller-results lput current-hour-potential-buyers hourly-buyer-seller-results
  set hourly-buyer-seller-results lput current-hour-potential-sellers hourly-buyer-seller-results
  set hourly-buyer-seller-results lput current-hour-actual-buyers hourly-buyer-seller-results
  set hourly-buyer-seller-results lput current-hour-actual-sellers hourly-buyer-seller-results

  file-print csv:to-row hourly-buyer-seller-results
;    set daily-prosumer-results lput sum (hourly-demand-list) daily-prosumer-results
;    set daily-prosumer-results lput sum (hourly-generation-list) daily-prosumer-results
    file-flush
    file-close
end

to out-put-to-window
  output-show (word "Day" day-now)
  output-show [daily-prosumer-results] of prosumers
end
@#$#@#$#@
GRAPHICS-WINDOW
201
11
740
551
-1
-1
16.1
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
4
10
104
43
NIL
Setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
103
10
199
43
NIL
Go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
2
84
82
129
NIL
num-houses
17
1
11

INPUTBOX
3
131
83
191
Start-Hour
0.0
1
0
Number

INPUTBOX
3
192
165
252
evolution-threshold-e
0.5
1
0
Number

PLOT
740
11
1057
184
Current Hour Demand & Generation
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Generation" 1.0 0 -8053223 true "" "if ticks > 0 [plot sum [current-hour-generation] of prosumers]"
"Demand" 1.0 0 -7500403 true "" "if ticks > 0 [plot sum [current-hour-demand] of prosumers]"

PLOT
740
185
1374
396
Current Hour Buy from Prosumers
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Bought" 1.0 0 -10022847 true "" "if ticks > 0[plot sum [current-hour-actual-buy] of prosumers]"
"Sold" 1.0 0 -10899396 true "" "if ticks > 0 [plot sum [current-hour-actual-sell] of prosumers]"

MONITOR
147
84
199
129
Hour
hour-now
17
1
11

INPUTBOX
2
254
163
314
stackelberg-threshold-e
4.0
1
0
Number

PLOT
1058
11
1373
183
Average Price
NIL
NIL
0.0
1.0
0.0
0.5
true
false
"" ""
PENS
"default" 1.0 0 -7858858 true "" "if ticks > 0 [\nifelse count prosumers with [current-hour-prosumer-type = \"seller\"] > 0 \n[plot mean [current-hour-sell-price-pie] of prosumers with [current-hour-prosumer-type = \"seller\"]]\n[plot row-sell]]"

SWITCH
3
46
138
79
Run-New-File?
Run-New-File?
1
1
-1000

OUTPUT
201
602
1375
784
13

TEXTBOX
4
314
175
384
Threshold e is the Stackelberg game termination criterion defined as equation 38 in the paper. Indicating buyer ask close to sell potential.
11
0.0
1

MONITOR
82
84
146
129
Day
day-now
17
1
11

PLOT
739
397
1373
603
Total Energy Buy and Sell
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Actually Sold" 1.0 0 -5298144 true "" "plot sum [current-hour-actual-sell] of prosumers"
"EnergyforSell" 1.0 0 -12087248 true "" "plot sum [current-hour-generation - current-hour-demand] of prosumers with [current-hour-prosumer-type = \"seller\"]"

INPUTBOX
4
391
83
451
row-buy
0.465
1
0
Number

INPUTBOX
83
391
158
451
row-sell
0.18
1
0
Number

MONITOR
201
552
331
597
adjustment-eta1
precision adjustment-eta1 3
17
1
11

MONITOR
332
552
434
597
Total Prosumers
count prosumers
17
1
11

SWITCH
5
603
200
636
Save-Results?
Save-Results?
0
1
-1000

SLIDER
3
454
177
487
Flexible-Demand-Ratio
Flexible-Demand-Ratio
0
100
30.0
1
1
%
HORIZONTAL

MONITOR
435
552
525
597
Average Price
precision (mean filter [i -> i > 0] current-hour-sell-price-pie-list) 3
17
1
11

SLIDER
4
492
176
525
battery-size
battery-size
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
4
527
176
560
price-subsidy
price-subsidy
0
0.4
0.05
0.01
1
NIL
HORIZONTAL

MONITOR
526
552
583
597
Sellers
count prosumers with [current-hour-prosumer-type = \"seller\"]
17
1
11

MONITOR
582
553
639
598
Buyers
count prosumers with [current-hour-prosumer-type = \"buyer\"]
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
