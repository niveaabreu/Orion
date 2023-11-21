import os
import mysql.connector
from mysql.connector import errorcode
from dotenv import load_dotenv

# Carregar variáveis de ambiente do arquivo .env
load_dotenv()

# Configurar o dicionário com as informações do .env
config = {
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASSWORD'),
    'host': os.getenv('DB_HOST'),
    'database': '',  # Não especificar a base de dados inicialmente
    'raise_on_warnings': True,
}

# Crie uma conexão separada para criar a base de dados
create_db_config = {
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASSWORD'),
    'host': os.getenv('DB_HOST'),
    'raise_on_warnings': True,
}

# Carregue o conteúdo do seu script SQL
with open('script.sql', 'r') as file:
    sql_script = file.read()

try:
    # Conecte-se para criar a base de dados
    create_db_cnx = mysql.connector.connect(**create_db_config)

    # Crie um cursor
    create_db_cursor = create_db_cnx.cursor()

    # Obtenha o nome da base de dados do .env
    db_name = os.getenv('DB_DATABASE_NAME')

    # Crie a base de dados se não existir
    create_db_cursor.execute(f"CREATE DATABASE IF NOT EXISTS {db_name}")

    # Commitar as mudanças
    create_db_cnx.commit()

    print(f"Banco de dados '{db_name}' criado com sucesso.")

except mysql.connector.Error as err:
    print(f"Erro ao criar banco de dados: {err}")

finally:
    # Feche o cursor e a conexão
    if 'create_db_cursor' in locals() and create_db_cursor is not None:
        create_db_cursor.close()
    if 'create_db_cnx' in locals() and create_db_cnx is not None:
        create_db_cnx.close()

# Atualize o dicionário de configuração com o nome da base de dados
config['database'] = db_name

# Conecte-se novamente para executar o script SQL
try:
    # Conecte-se à base de dados
    cnx = mysql.connector.connect(**config)

    # Crie um cursor
    cursor = cnx.cursor()

    # Divida o script SQL em instruções individuais
    sql_commands = sql_script.split(';')

    for command in sql_commands:
        if command.strip():  # Ignora linhas em branco
            cursor.execute(command)

    # Commitar as mudanças
    cnx.commit()

    print("Script SQL executado com sucesso!")

except mysql.connector.Error as err:
    print(f"Erro ao executar script SQL: {err}")

finally:
    # Feche o cursor e a conexão
    if 'cursor' in locals() and cursor is not None:
        cursor.close()
    if 'cnx' in locals() and cnx is not None:
        cnx.close()
