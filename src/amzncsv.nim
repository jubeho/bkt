import std/[parsecsv,tables,strutils,times]

proc parseAmznHistory*(fp: string, sep: char = ','): Table[string, OrderedTable[string, string]] # key OrderID, valkey: column, valval: value

proc parseAmznHistory*(fp: string, sep: char = ','): Table[string, OrderedTable[string, string]] =
  # Website,"Order ID","Order Date","Purchase Order Number","Currency","Unit Price","Unit Price Tax","Shipping Charge",
  # "Total Discounts","Total Owed","Shipment Item Subtotal","Shipment Item Subtotal Tax","ASIN","Product Condition","Quantity",
  # "Payment Instrument Type","Order Status","Shipment Status","Ship Date","Shipping Option","Shipping Address",
  # "Billing Address","Carrier Name & Tracking Number","Product Name","Gift Message","Gift Sender Name","Gift Recipient Contact Details","Item Serial Number"

  result = initTable[string, initOrderedTable[string, string]()]()
  var csv: CsvParser
  csv.open(fp, sep)
  csv.readHeaderRow()
  while csv.readRow():
    var tab = initOrderedTable[string, string]()
    for i in 0..len(csv.headers)-1:
      tab[csv.headers[i]] = csv.row[i]
    if hasKey(result, "Order ID"):
      echo "wow - duplicate order id :("
    else:
      result[tab["Order ID"]] = tab

when isMainModule:
  var minDate: DateTime
  var maxDate: DateTime
  var fromDate: DateTime = parse("2024-01-01", "yyyy-MM-dd")
  var toDate: DateTime = parse("2024-12-31", "yyyy-MM-dd")
  var sum = 0.0
  var sum2023 = 0.0
  let recs = parseAmznHistory("amzn.csv", ',')
  var i = 0
  for k, v in pairs(recs):
    var priceString = replace(v["Total Owed"], ",", "")
    let price = parseFloat(priceString)
    var shipDateString = v["Ship Date"]
    if not startsWith(shipDateString, "20"):
      shipDateString = v["Order Date"]
    let shipDate = parse(shipDateString[0..18], "yyyy-MM-dd'T'HH:mm:ss")
    if i == 0:
      minDate = shipDate
      maxDate = shipDate
      inc(i)
    if shipDate > maxDate:
      maxDate = shipDate
    if shipDate < minDate:
      minDate = shipDate
    sum = sum + price
    if price > 500.0:
      echo v["Product Name"], ": ", $price, " :> ", $shipDate
    if shipDate <= toDate and shipDate >= fromDate:
      sum2023 = sum2023 + price
  echo "Min Date: ", $minDate
  echo "Max Date: ", $maxDate
  echo "Summe: ", $sum
  echo "2023: ", $sum2023

  let id = "304-4166904-6973961"
  if hasKey(recs, id):
    echo recs[id]
