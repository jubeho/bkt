import std/[tables,strformat,parsecsv,strutils,math]

type
  AccountData* = ref object
    transactions*: Table[string, Table[string, string]] # key: uid, valkey: csv-colname, valval: value

proc openTransactions*(fp: string): AccountData
proc importCsvFile*(fp: string, ac: var AccountData)
proc fetchTransactionsForDestName*(ac: AccountData, name: string): Table[string, Table[string, string]]
proc calcTransactionsTurnover*(transactions: Table[string, Table[string, string]]): float
proc calcTransactionsIncome*(transactions: Table[string, Table[string, string]]): float

proc openTransactions*(fp: string): AccountData =
  ## opens and loads the bkt transaction file
  discard

proc importCsvFile*(fp: string, ac: var AccountData) =
  ## imports the given csv data into ac.transactions
  var csv: CsvParser

  # open users.csv, separator is ;
  csv.open(fp, ';')
  csv.readHeaderRow()
  while csv.readRow():
    let uid = join(@[
      csv.rowEntry("IBAN Auftragskonto"),
      csv.rowEntry("Valutadatum"),
      csv.rowEntry("IBAN Zahlungsbeteiligter"),
      csv.rowEntry("Betrag"),
      csv.rowEntry("Saldo nach Buchung"),
    ], "|")
    var tab = initTable[string, string]()
    for col in csv.headers:
      tab[col] = csv.rowEntry(col)
      
    ac.transactions[uid] = tab
  csv.close()

proc fetchTransactionsForDestName*(ac: AccountData, name: string): Table[string, Table[string, string]] =
  result = initTable[string, initTable[string, string]()]()
  for uid, tran in pairs(ac.transactions):
    if contains(toLowerAscii(tran["Name Zahlungsbeteiligter"]), toLowerAscii(name)):
      result[uid] = tran

proc calcTransactionsTurnover*(transactions: Table[string, Table[string, string]]): float =
  result = 0.0
  for transaction in values(transactions):
    var amountString = transaction["Betrag"]
    amountString = replace(amountString, ",", ".")
    try:
      var amount = parseFloat(amountString)
      result = result + amount
    except ValueError:
      echo(fmt("could not parse amountString to float: {amountString}"))

  result = round(result, 2)

proc calcTransactionsIncome*(transactions: Table[string, Table[string, string]]): float =
  result = 0.0
  for transaction in values(transactions):
    var amountString = transaction["Betrag"]
    amountString = replace(amountString, ",", ".")
    try:
      var amount = parseFloat(amountString)
      if amount > 0.00:
        result = result + amount
    except ValueError:
      echo(fmt("could not parse amountString to float: {amountString}"))

  result = round(result, 2)
      
when isMainModule:
  var ac = new(AccountData)
  importCsvFile("2.csv", ac)
  echo len(ac.transactions)

  let trans = fetchTransactionsForDestName(ac, "amazon")
  echo len(trans)

  let sum = calcTransactionsTurnover(trans)
  echo sum
  let income = calcTransactionsIncome(ac.transactions)
  echo income
  
