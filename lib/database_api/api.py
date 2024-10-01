from typing import Annotated, Optional
import pandas as pd
from pydantic import BaseModel
from fastapi import FastAPI, HTTPException, Header
import psycopg as pg

responses = {
    200: {"description": "OK"},
    401: {"description": "Unauthorized user"},
    404: {"description": "Value Error"},
    413: {"description": "Not enough items in the database"},
}

users_pass = {
    "alice": "wonderland",
    "bob": "builder",
    "clementine": "mandarine"
}

admin_pass = {'admin': '4dm1N'}

api = FastAPI(
    title='FastAPI Exam',
    description='API to generate MCQ for authorized users',
    version='0.1.0',
    openapi_tags=[
        {'name': 'home', 'description': 'default functions'},
        {'name': 'items', 'description': 'mcq functions'},
        {'name': 'admin', 'description': 'admin functions'},
    ]
)


class Question(BaseModel):
    """Question structure

    Args:
        BaseModel (_type_): _description_
    """
    question: str
    subject: str
    use: str
    correct: str
    responseA: str
    responseB: str
    responseC: Optional[str] = None
    responseD: Optional[str] = None
    remark: Optional[str] = None


def load_database():
    return pd.read_excel('questions_en.xlsx', header=0)
df = load_database()


@api.get('/', tags=['home'])
async def get_welcome_page():
    return {'data': 'Welcome to the FastAPI exam page. The API is working fine.'}


@api.get('/db', name='Get the number of questions in the database', tags=['home'])
async def get_number_questions_in_db():
    return {'# questions in the db': len(df)}


@api.get('/headers', tags=['admin'])
async def read_headers(user_agent: Annotated[str | None, Header()] = None):
    return {"User-Agent": user_agent}


@api.get('/auth', name='Is user authorized?', tags=['home'])
async def read_authorization(auth: Annotated[str | None, Header(description='Authorization header')] = None):
    username = auth.split(' ')[-1].split(':')[0]
    password = auth.split(':')[-1]
    if password == users_pass.get(username) and users_pass.get(username) is not None:
        return {
            'username': username,
            'Authorization': True
        }
    else:
        return {
            'username': username,
            'Authorization': False
        }


@api.get('/mcq/{use:str}/{subject:str}', name='Create a new MCQ', tags=['items'], responses=responses)
async def get_mcq(use: str, subject: str, number_questions: int, auth: Annotated[str, Header(description='Authorization header')]):
    """Create a random MCQ for a given use, subject and with a limited number of questions.

    Args:
        use (_type_): _description_
        subject (_type_): _description_
        number_questions (int): _description_
    """
    username = auth.split(' ')[-1].split(':')[0]
    password = auth.split(':')[-1]
    if password == users_pass.get(username) and users_pass.get(username) is not None:
        pass
    else:
        raise HTTPException(
            status_code=401,
            detail='User is not authorized to use the API'
        )
    if number_questions not in [5, 10, 20]:
        raise HTTPException(
            status_code=404,
            detail='Number of questions should be 5, 10 or 20.'
        )
    df_filtered = df.loc[(df['use'] == use) & (df['subject'] == subject)]
    try:
        mcq = df_filtered.sample(n=number_questions, replace=False, axis=0, ignore_index=True)
    except ValueError:
        raise HTTPException(
            status_code=413,
            detail='Not enough number of questions in the database, please reduce the input number.'
        )
    else:
        return {'mcq': mcq.to_json(orient='records')}


@api.put('/mcq', name='Add a new question to the database', tags=['admin'])
async def put_new_question(question: Question, auth: Annotated[str, Header(description='Authorization header')]):
    username = auth.split(' ')[-1].split(':')[0]
    password = auth.split(':')[-1]
    if password == admin_pass.get(username) and admin_pass.get(username) is not None:
        df.loc[len(df), :] = pd.Series(question.model_dump(), dtype=str)
        return question
    else:
        raise HTTPException(
            status_code=401,
            detail='Unauthorized admin acces.'
        )

