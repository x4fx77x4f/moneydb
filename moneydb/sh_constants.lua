--@shared
MDB_KEY = 'moneydb' -- internal
MDB_MONEY_WIDTH = 32 -- maximum of 32
MDB_ACTION_INCREASE = 0x00
MDB_ACTION_DECREASE = 0x01
MDB_ACTION_TRANSFER = 0x02
MDB_ACTION_GET = 0x03
MDB_ACTION_SET = 0x04
MDB_ACTION_DUMP = 0x05 -- debug
MDB_ACTION_AUTH_ENT = 0x06 -- internal
MDB_ACTION_DEAUTH_ENT = 0x07 -- internal
MDB_ACTION_AUTH_PLY = 0x08 -- internal
MDB_ACTION_DEAUTH_PLY = 0x09 -- internal
MDB_RESPONSE_SUCCESS = 0x00
MDB_RESPONSE_BALANCE = 0x01 -- internal
MDB_RESPONSE_FAILURE = 0xff
