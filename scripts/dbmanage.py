#!/usr/bin/env python3

import mysql.connector
from datetime import datetime
import argparse
import requests
import sys
import json
from tabulate import tabulate

# Read the JSON file
with open("/home/centos/scripts/config.json") as file:
    json_data = json.load(file)

# Access the passwords from the dictionary
towerpass =  json_data.get('dbtoweruserpass')
# Define and parse the command-line arguments
parser = argparse.ArgumentParser(description="Manage data in the 'tower' table.")
subparsers = parser.add_subparsers(title='subcommands', dest='subcommand', required=True)

# Subparser for inserting or creating data
parser_create = subparsers.add_parser('create', help='Create Template DB')
parser_create.add_argument('-p','--password', default="",  help='DB password')

# Subparser for deleting the  data
parser_del = subparsers.add_parser('delete', help='delete the record')
parser_del.add_argument('-p','--password', default="",  help='DB password')
parser_del.add_argument('-f2','--field2',required=True, help='Value for Field2 (NAME)')

# Subparser for inserting or updating data
parser_data = subparsers.add_parser('insert', help='Insert or update data')
parser_data.add_argument('-p','--password', required=True, help='DB password')
parser_data.add_argument('-f1','--field1', help='Value for Field1 DATETIME')
parser_data.add_argument('-f2','--field2',required=True, help='Value for Field2 NAME')
parser_data.add_argument('-f3','--field3',required=True, help='Value for Field3 ROLE')

# Subparser for querying all data
parser_query = subparsers.add_parser('query', help='Query all data')
parser_query.add_argument('-p','--password', required=True, help='DB password')

args = parser.parse_args()

"""
# Connect to the MySQL server
cnx = mysql.connector.connect(
    host="10.123.1.25",
    user="toweruser",
    password=towerpass,
)

cursor = cnx.cursor()
#cursor.execute('CREATE DATABASE IF NOT EXISTS tower')
try:
    cursor.execute('USE tower')
except:
    sys.exit("Please create DB using /home/centos/scripts/dbmanage.py create or curl -X POST http://localhost/configure_mysql")
"""
def check_db_exists(database_name='tower'):
    # Connect to the MySQL server
    cnx = mysql.connector.connect(
    host="10.123.1.25",
    user="toweruser",
    password=towerpass,
    )

    cursor = cnx.cursor()
    cursor.execute("SHOW DATABASES")
    databases = cursor.fetchall()
    for db in databases:
        if db[0] == database_name:
            return True,cnx
    return False,cnx


# Perform the specified action

if args.subcommand == 'create':
    try:
        # Make the API call .
        # Endpoint : curl -X POST http://localhost/configure_mysql
        endpoint = "http://localhost/configure_mysql"
        response = requests.post(endpoint)
        response.raise_for_status()  # Create an exception if the request was not successful
        #print(response.json())
        print(f"{response.json().get('result')}")
    except requests.exceptions.RequestException as e:
        print(f"Error creating database: {e}")


if args.subcommand == 'delete':
    status,cnx = check_db_exists()
    if not status:
        print("Please create DB using /home/centos/scripts/dbmanage.py create or curl -X POST http://localhost/configure_mysql")
    try:
        cursor = cnx.cursor()
        cursor.execute('USE tower')

        # Check if the record exists
        cursor.execute("SELECT Field2 FROM tower WHERE Field2 = %s", (args.field2,))
        existing_field2 = cursor.fetchone()

        if existing_field2:
        # Delete the record
            cursor.execute("DELETE FROM tower WHERE Field2 = %s", (args.field2,))
            cnx.commit()
            cursor.close()
            print("Record {} deleted successfully.".format(args.field2))
        else:
            print("Record {} not found.".format(args.field2))
    except mysql.connector.Error as error:
        print(f"Failed to delete record: {error}")
    finally:
        if cursor:
            cursor.close()
        if cnx:
            cnx.close()


if args.subcommand == 'insert':
    status,cnx = check_db_exists()
    if not status:
        print("Please create DB using /home/centos/scripts/dbmanage.py create or curl -X POST http://localhost/configure_mysql")

    cursor = cnx.cursor()
    cursor.execute('USE tower')
    if args.field2 and (args.field1 or args.field3):
        # Check if data already exists
        select_query = "SELECT * FROM tower WHERE Field2 = %s"
        #print(select_query)
        current_date_time = datetime.now()
        cursor.execute(select_query,(args.field2,))
        existing_data = cursor.fetchone()
        #print(existing_data)

        # Perform insert or update based on data existence
        if existing_data:
            msg = "Field1 : {} , Field2 : {} , Field3 : {}".format(existing_data[0].strftime("%Y-%m-%d %H:%M:%S"),existing_data[1],existing_data[2] )
            print("\n\tPrevious data : {}".format(msg))
            update_query = "UPDATE tower SET "
            update_data = []
            if args.field1:
                update_query += "Field1 = %s, "
                update_data.append(args.field1)
            else:
                update_query += "Field1 = %s, "
                update_data.append(current_date_time.strftime("%Y-%m-%d %H:%M:%S"))
            if args.field3:
                update_query += "Field3 = %s, "
                update_data.append(args.field3)

            update_query = update_query.rstrip(", ") + " WHERE Field2 = %s"
            update_data.insert(2,args.field2)
            #print(update_data)
            #print(update_query,tuple(update_data))

            cursor.execute(update_query, tuple(update_data))
            cnx.commit()
            msg = "Field1 : {} , Field2 : {} , Field3 : {}".format(datetime.strptime(update_data[0],'%Y-%m-%d %H:%M:%S'),update_data[2],update_data[1])
            print("\tUpdated  data : {}".format(msg))
            print("\n\tData updated successfully.\n")
        else:
            insert_query = "INSERT INTO tower (Field1, Field2, Field3) VALUES (%s, %s, %s)"
            if args.field1:
                current_date_time = datetime.strptime(args.field1, '%Y-%m-%d %H:%M:%S')
            data = (current_date_time.strftime("%Y-%m-%d %H:%M:%S"), args.field2, args.field3)
            cursor.execute(insert_query, data)
            cnx.commit()
            msg = "Field1 : {} , Field2 : {} , Field3 : {}".format(data[0],data[1],data[2])
            print("\n\tInserting Data : {}".format(msg))
            print("\n\tData inserted successfully.\n")
    else:
        print("To insert or update data, provide the value for Field2 and at least one of Field1 or Field3.")

elif args.subcommand == 'query':
    status,cnx = check_db_exists()
    if not status:
        print("DB does not exist. Please create DB first using '/home/centos/scripts/dbmanage.py create' or 'curl -X POST http://localhost/configure_mysql'")
    cursor = cnx.cursor()
    cursor.execute('USE tower')
    select_all_query = "SELECT * FROM tower"
    cursor.execute(select_all_query)
    rows = cursor.fetchall()
    if rows:
        print("\nData in the 'tower' table:")
        print("=========================\n")
        columns = [column[0] for column in cursor.description]
        print(tabulate(rows, headers=columns))
        print()
    else:
        print("No data found in the 'tower' table.")
