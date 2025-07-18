FROM public.ecr.aws/lambda/python:3.11

# For Lambda container images
COPY app.py ${LAMBDA_TASK_ROOT}
COPY requirements.txt ${LAMBDA_TASK_ROOT}

RUN pip install -r requirements.txt

CMD ["app.handler"]