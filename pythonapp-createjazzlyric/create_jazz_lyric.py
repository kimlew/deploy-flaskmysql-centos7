''' Python Flask app that lets you input values to make a jazz lyric. '''

from datetime import datetime
from dotenv import load_dotenv
from flask import Flask, render_template, request, g
import mysql.connector
from conn_vars_dict import conn_dict

VOWEL_LIST = list('aeiouy')
CONSONANT_LIST = list('bcdfghijklmnpqrstvwxz')

load_dotenv()
app = Flask(__name__)


@app.before_request
def before_request():
    ''' Gets the connection variables to connect to MySQL. '''
    g.conn = mysql.connector.connect(**conn_dict)


@app.route('/')
@app.route('/entry')
def entry_page() -> str:
    ''' Creates the Create a Jazz Lyric page. '''
    msg_params = {
        "need_vowel1_msg": "",
        "need_vowel2_msg": "",
        "need_number_msg": "",
        "need_consonant_msg": ""
    }
    return render_template('create_lyric.html',
                           the_title='Create a Jazz Lyric',
                           the_msg_params=msg_params,)


@app.route('/show_lyric', methods=['POST'])
def create_lyric() -> str:
    ''' Converts the inputs to lowercase, makes sure the correct type is
    entered & saves the lyric into the MySQL database. '''
    page_title = 'See Jazz Lyric'

    vowel1 = request.form['vowel1'].lower()
    vowel2 = request.form['vowel2'].lower()
    vowel2_amount = 0

    # Try-Except-Finally block for when vowel2_amount field is ''.
    try:
        vowel2_amount = int(request.form['vowel2_amount'])
    except ValueError as val_err:
        print(val_err)

    consonant = request.form['consonant'].lower()

    error_count, msg_params = validate_lyric_form(vowel1, vowel2,
                                                  vowel2_amount, consonant)
    if error_count > 0:
        return render_template('create_lyric.html',
                               the_title='Create a Jazz Lyric',
                               the_msg_params=msg_params, )

    lyric = (
        f" Shooo "
        f"d{vowel1}p "
        f"b{vowel1 * 2} "
        f"{consonant}{vowel2 * int(vowel2_amount)} "
        f"z{'e' * 8}... "
    )

    cursor = g.conn.cursor()

    try:
        nowdatetime = datetime.now()

        sql = """INSERT INTO lyric(lyric, date_created) VALUES (%s, %s)"""
        cursor.execute(sql, (lyric, nowdatetime))

        g.conn.commit()
    finally:
        g.conn.close()

    vowel_count = count_vowels(lyric)
    lyric_params = {
        "the_page_title":  page_title,
        "the_vowel1": vowel1,
        "the_vowel2": vowel2,
        "the_vowel2_amount": vowel2_amount,
        "the_consonant": consonant,
        "the_lyric": lyric,
        "the_vowel_count": vowel_count
    }

    return render_template('show_lyric.html', the_lyric_params=lyric_params,)


def validate_lyric_form(vowel1, vowel2, vowel2_amount, consonant):
    ''' Makes sure vowels and consonants are correctly entered in fields. '''
    msg_params = {
        "need_vowel1_msg": "",
        "need_vowel2_msg": "",
        "need_number_msg": "",
        "need_consonant_msg": ""
    }

    need_vowel_msg = 'You must enter a vowel.'
    need_number_msg = 'You must enter a number from 3-9.'
    need_consonant_msg = 'You must enter a consonant.'

    error_count = 0

    if vowel1 not in VOWEL_LIST:
        # Render entry page again & show, 'You must enter a vowel.'
        error_count += 1
        msg_params["need_vowel1_msg"] = need_vowel_msg

    if vowel2 not in VOWEL_LIST:
        # Render entry page again & show, 'You must enter a vowel.'
        error_count += 1
        msg_params["need_vowel2_msg"] = need_vowel_msg

    if vowel2_amount < 3 or vowel2_amount > 9:
        # Render entry page again & show, 'You must enter a number from 3-9.'
        error_count += 1
        msg_params["need_number_msg"] = need_number_msg

    if consonant not in CONSONANT_LIST:
        # Render entry page again & show, 'You must enter a consonant.'
        error_count += 1
        msg_params["need_consonant_msg"] = need_consonant_msg

    return (error_count, msg_params)


def count_vowels(lyric) -> str:
    ''' Checks if is a vowel & returns the number of vowels. '''
    return len([vowel for vowel in lyric if vowel in VOWEL_LIST])


@app.route('/show_song', methods=['GET'])
def show_song() -> str:
    ''' Displays all the lyrics in the MySQL database as a song. '''
    cursor = g.conn.cursor()

    try:
        sql = """SELECT lyric, date_created
            FROM lyric WHERE date_deactivated IS NULL
            ORDER BY date_created DESC"""
        cursor.execute(sql)
        all_lyrics = cursor.fetchall()
    finally:
        g.conn.close()

    page_title = 'See Jazz Song'

    return render_template('show_song.html', page_title=page_title,
                           all_lyrics=all_lyrics)


if __name__ == '__main__':
    app.run()
