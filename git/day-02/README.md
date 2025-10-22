Pipeline CI

O arquivo da raiz `.github/workflows/first-workflow.yaml` da linha 45 a linha ?? 

para o workflow acessar um código
uses: actions/checkout@v5 

para enviar imagem pro registry
a. docker login > docker/login-action@v3
    para senha > usar secrets (na propria documentacao da action tem como usar) > depois repo > settings > secrets and variables > actions > new repository secret
b. build da imagem 
c. push

b e c tem uma action tambem > docker/build-push-action@v6

após a execução da pipeline, docker container run -d -p 8080:5000 thiagoduran/github-actions-test:v15
 podera ser executado para ver o app em execucao