import std/[tables,strformat,parsecsv,strutils,math,os]

const
  storagedata = "bkt-account-data.csv"

type
  AccountData* = ref object
    headerRow*: seq[string]
    transactions*: Table[string, OrderedTable[string, string]] # key: uid, valkey: csv-colname, valval: value

proc openTransactions*(fp: string): AccountData
proc writeTransactions*(fp: string, ac: AccountData)
proc importCsvFile*(fp: string, ac: var AccountData)
proc fetchTransactionsForDestName*(ac: AccountData, name: string): (Table[string, OrderedTable[string, string]], Table[string, int])
proc filterTransactions*(ac: AccountData, name: string = "", minAmmount: float = 0.00): (Table[string, OrderedTable[string, string]], Table[string, int])
proc calcTransactionsTurnover*(transactions: Table[string, OrderedTable[string, string]]): (float, Table[string, float])
proc calcTransactionsIncome*(transactions: Table[string, OrderedTable[string, string]]): (float, Table[string, float])

proc getAmount(tran: OrderedTable[string, string]): float
proc amountStringToFloat(amountString: string): float


proc openTransactions*(fp: string): AccountData =
  ## opens and loads the bkt transaction file
  result = new(AccountData)
  if not fileExists(fp):
    return result
  importCsvFile(fp, result)

proc importCsvFile*(fp: string, ac: var AccountData) =
  ## imports the given csv data into ac.transactions
  var csv: CsvParser

  # open users.csv, separator is ;
  csv.open(fp, ';')
  csv.readHeaderRow()
  ac.headerRow = csv.headers
  while csv.readRow():
    let uid = join(@[
      csv.rowEntry("IBAN Auftragskonto"),
      csv.rowEntry("Valutadatum"),
      csv.rowEntry("IBAN Zahlungsbeteiligter"),
      csv.rowEntry("Betrag"),
      csv.rowEntry("Saldo nach Buchung"),
    ], "|")
    var tab = initOrderedTable[string, string]()
    for col in csv.headers:
      tab[col] = csv.rowEntry(col)
      
    ac.transactions[uid] = tab
  csv.close()

proc writeTransactions*(fp: string, ac: AccountData) =
  let sep = ";"
  var txt = ""
  txt.add(join(ac.headerRow, sep))
  txt.add("\n")
  
  for transaction in values(ac.transactions):
    var row: seq[string] = @[]
    for val in values(transaction):
      row.add(val)
    txt.add(join(row, sep))
    txt.add("\n")
  try:
    writeFile(fp, txt)
  except:
    echo "somethings failed writing data :("

proc filterTransactions*(ac: AccountData, name: string = "", minAmmount: float = 0.00): (Table[string, OrderedTable[string, string]], Table[string, int]) =
  var trans = initTable[string, initOrderedTable[string, string]()]()
  var names = initTable[string, int]()

  for uid, tran in pairs(ac.transactions):
    let amount = getAmount(tran)
    if amount <= minAmmount:
      trans[uid] = tran
  return (trans, names)

proc fetchTransactionsForDestName*(ac: AccountData, name: string): (Table[string, OrderedTable[string, string]], Table[string, int]) =
  var trans = initTable[string, initOrderedTable[string, string]()]()
  var names = initTable[string, int]()
  
  for uid, tran in pairs(ac.transactions):
    if contains(toLowerAscii(tran["Name Zahlungsbeteiligter"]), toLowerAscii(name)):
      if hasKey(names, tran["Name Zahlungsbeteiligter"]):
        names[tran["Name Zahlungsbeteiligter"]] = names[tran["Name Zahlungsbeteiligter"]] + 1
      else:
        names[tran["Name Zahlungsbeteiligter"]] = 1
      trans[uid] = tran
  return (trans, names)

proc calcTransactionsTurnover*(transactions: Table[string, OrderedTable[string, string]]): (float, Table[string, float]) =
  var sum = 0.0
  var names = initTable[string, float]()
  for tran in values(transactions):
    let amount = getAmount(tran)
    var name = tran["Name Zahlungsbeteiligter"]
    sum = sum + amount
    if hasKey(names, name):
      names[name] = names[name] + amount
    else:
      names[name] = amount

  sum = round(sum, 2)
  for name in keys(names):
    names[name] = round(names[name], 2)
  return (sum, names)

proc calcTransactionsIncome*(transactions: Table[string, OrderedTable[string, string]]): (float, Table[string, float]) =
  var sum = 0.0
  var names = initTable[string, float]()
  for tran in values(transactions):
    let amount = getAmount(tran)
    var name = tran["Name Zahlungsbeteiligter"]
    if amount > 0.00:
      sum = sum + amount
      if hasKey(names, name):
        names[name] = names[name] + amount
      else:
        names[name] = amount

  sum = round(sum, 2)
  for name in keys(names):
    names[name] = round(names[name], 2)
  return (sum, names)
      
when isMainModule:
  var ac = openTransactions(storagedata)
  importCsvFile("1.csv", ac)
  echo len(ac.transactions)

  let (trans, names) = fetchTransactionsForDestName(ac, "amazon")
  echo len(trans)
  for name, i in pairs(names):
    echo "\t", name, ": ", $i

  let (sum, sumByNames) = calcTransactionsTurnover(trans)
  echo sum
  # for tran in values(trans):
  #   echo "\t", tran["
  for name, val in pairs(sumByNames):
    echo "\t", name, ": ", $val
  
  let (income, incomes) = calcTransactionsIncome(ac.transactions)
  echo income

  let (t, n) = filterTransactions(ac, "", -1000)
  echo len(t)
  var minSum = 0.00
  for tran in values(t):
    echo "\t", tran["Name Zahlungsbeteiligter"], ": ", tran["Betrag"], " --->>> ", tran["Verwendungszweck"]
    minSum = minSum + getAmount(tran)
  echo minSum
  
  writeTransactions(storagedata, ac)

proc getAmount(tran: OrderedTable[string, string]): float =
  return amountStringToFloat(tran["Betrag"])
  
proc amountStringToFloat(amountString: string): float =
  result = 0.00
  let amntStr = replace(amountString, ",", ".")
  try:
    var amount = parseFloat(amntStr)
    result = round(amount, 2)
  except ValueError:
    echo(fmt("could not parse amountString to float: {amntStr}"))

  return result

    
  
