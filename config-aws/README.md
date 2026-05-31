Configurações na AWS feitas fora do template de Cloudformation do Backend (necessário criar a mão):

1. Criar itens do Frontend:
    * Criar bucket S3 para receber os arquivos do frontend estático. Sugestão de nome: tcc-agendamento-frontend
      * Bucket deve ser acessível publicamente
      * Ativar "Static website hosting"
    * Criar certificado no ACM com o domínio desejado
    * Criar Cloudfront
      * Origin: Bucket S3 do frontend
      * Behavior: Default - Mandar para o bucket S3
        * Viewer protocol policy: redirect HTTP to HTTPS
        * Cache policy: CachingOptimized
        * Response headers policy: adicionar policy NoIndexSite, para que os crawlers de busca não indexem o site
2. Criar pipeline do Frontend
    * Criar bucket de artefatos da pipeline
    * Criar Role para a pipeline com as permissões:
      * s3-tcc-agendamento-frontend-read-write - Permissão para escrever no bucket do frontend
      * Escrever no bucket de artefatos da pipeline
    * Adicionar etapa para source - Conectar com Github
    * Adicionar etapa de build
      * Criar role para o Codebuild com as permissões:
        * s3-tcc-agendamento-frontend-read-write - Permissão para escrever no bucket do frontend
      * Usar arquivo buildspec para buildar
      * Adicionar variáveis de ambiente nas configurações de env do Codebuild
    * Criar etapa de deploy, apontando para o bucket S3 criado anteriormente
    * Recomendado: adicionar etapa de invalidação de cache do cloudfront