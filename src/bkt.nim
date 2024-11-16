import std/[tables,strformat,parsecsv,strutils]

type
  AccountData* = ref object
    transactions*: Table[string, Table[string, string]] # key: uid, valkey: csv-colname, valval: value

proc openTransactions*(fp: string): AccountData
proc importCsvFile*(fp: string, ac: var AccountData)
proc transactionsForDestName*(ac: AccountData, name: string): Table[string, Table[string, string]]

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

proc transactionsForDestName*(ac: AccountData, name: string): Table[string, Table[string, string]] =
  result = initTable[string, initTable[string, string]()]()
  for uid, tran in pairs(ac.transactions):
    if contains(toLowerAscii(tran["Name Zahlungsbeteiligter"]), toLowerAscii(name)):
      result[uid] = tran
  
when isMainModule:
  var ac = new(AccountData)
  importCsvFile("2.csv", ac)
  echo len(ac.transactions)

  let trans = transactionsForDestName(ac, "amazon")
  echo len(trans)
  
