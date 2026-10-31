# Анализ потоков данных (DFA)

## Исходный код с нумерацией строк

```python
1  def process_transaction(user_id, amount, db_connection):
2      log_entry = "Start processing"
3      if amount > 0:
4          status = "approved"
5          balance = get_balance(user_id)
6          new_balance = balance - amount
7          update_balance(user_id, new_balance)
8      log_entry = "Transaction finished with status: " + status
9      file = open("audit_log.txt", "w")
10     file.write(log_entry)
11     return status
```

## Таблица Def-Use цепочек

| Переменная  | Def (определение) | Use (использование) |
|-------------|-------------------|---------------------|
| log_entry   | строка 2: `log_entry = "Start processing"` (мертвое присваивание); строка 8: `log_entry = "Transaction finished..."` | строка 10: `file.write(log_entry)` |
| status      | строка 4: `status = "approved"` (только если amount > 0) | строка 8: конкатенация строки; строка 11: `return status` |
| balance     | строка 5: `balance = get_balance(user_id)` | строка 6: `balance - amount` |
| new_balance | строка 6: `new_balance = balance - amount` | строка 7: `update_balance(user_id, new_balance)` |
| file        | строка 9: `file = open("audit_log.txt", "w")` | строка 10: `file.write(log_entry)` |

## Выявленные дефекты

### Дефект 1. Использование неинициализированной переменной

Переменная `status` определяется (def) только внутри блока `if amount > 0` (строка 4).
Если `amount <= 0`, поток управления попадает на строки 8 и 11, где происходит
use переменной `status` без единого def — программа упадет с исключением
`UnboundLocalError: local variable 'status' referenced before assignment`.

### Дефект 2. Мертвое присваивание (Dead Store)

На строке 2 переменной `log_entry` присваивается значение `"Start processing"`,
но до строки 8 оно никогда не читается: на строке 8 значение безусловно
перезаписывается. Присваивание на строке 2 — dead store, оно бесполезно.
Анализ du-цепочки (`def` в строке 2 не имеет соответствующего `use`) это ловит.

### Дефект 3. Утечка ресурса (Resource Leak)

На строке 9 файл `audit_log.txt` открывается в переменной `file`, но метод
`file.close()` нигде не вызывается — нет ни явного закрытия, ни конструкции
`with open(...)`. Дескриптор файла не освобождается: данные могут не попасть
на диск (не сделать flush), файл останется заблокированным, при повторных
вызовах — утечка файловых дескрипторов.

Дополнительное замечание: `db_connection` не используется вообще, а операции
`get_balance` / `update_balance` не обёрнуты в транзакцию — данные признаки
тоже стоит отметить в ревью.
