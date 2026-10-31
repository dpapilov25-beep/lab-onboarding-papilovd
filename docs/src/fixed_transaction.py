"""Исправленная версия функции process_transaction (Практика 7).

Исправленные дефекты:
1. status инициализируется до блока if (нет UnboundLocalError).
2. Убрано мертвое присваивание log_entry = "Start processing".
3. Файл открывается через with open(...) и закрывается автоматически.
"""


def process_transaction(user_id, amount, db_connection):
    status = "pending"
    if amount > 0:
        status = "approved"
        balance = get_balance(user_id)
        new_balance = balance - amount
        update_balance(user_id, new_balance)
    log_entry = "Transaction finished with status: " + status
    with open("audit_log.txt", "w") as file:
        file.write(log_entry)
    return status
