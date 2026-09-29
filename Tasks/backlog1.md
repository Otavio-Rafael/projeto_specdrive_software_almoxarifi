# Bugs e falhas encontradas para correção

## Ajustes globais

### 1. Remover regra global de aprovação para valores acima de R$ 50,00

Atualmente, todos os insumos e produtos cadastrados seguem uma regra global onde qualquer movimentação acima de R$ 50,00 exige permissão especial e fica pendente na tela **“Requisições e Aprovações”**.

Essa regra global deve ser removida.

A validação de aprovação deve seguir o valor definido individualmente no cadastro de cada insumo, dentro do campo **“Limite s/ Aprovação (R$)”**, localizado no menu **“Cadastrar novo insumo”**.

Ou seja, cada item deve respeitar seu próprio limite configurado, e não mais um valor fixo global de R$ 50,00.

---

### 2. Busca global por SKU deve redirecionar para o Catálogo Mestre

Independentemente da tela em que o usuário estiver, ao pesquisar por um SKU, o sistema deve redirecionar para a tela **“Catálogo Mestre”**.

Após o redirecionamento, o insumo correspondente ao SKU pesquisado já deve ser exibido na listagem ou destacado no resultado da busca.

---

## Header / Seleção de departamento

### 3. Troca de departamento no header não está funcionando

Ao clicar em outro departamento no header, nenhuma ação está sendo executada.

O comportamento esperado é que, ao selecionar um departamento, por exemplo, trocar de **TI** para **Marketing**, o sistema atualize o departamento selecionado e reflita essa alteração nas demais telas.

Após a troca, o novo departamento deve ficar pré-selecionado no restante do sistema, aplicando os filtros e informações correspondentes.

---

### 4. Adicionar opção “Todos os departamentos” no header

Deve ser adicionada no header uma opção chamada **“Todos os departamentos”**.

Ao selecionar essa opção, o sistema não deve aplicar filtro por departamento, nem deixar nenhum departamento pré-selecionado nas demais telas.

Essa opção deve permitir uma visão geral dos dados cadastrados no sistema, sem separação por departamento.

---

## Tela “Retirada & Scanner QR” / Movimentações

### 5. Atualizar nome da tela para “Movimentações”

A tela atualmente chamada **“Retirada & Scanner QR”** deve ter seu nome atualizado para **“Movimentações”**.

Esse novo nome representa melhor a função da tela, já que ela é utilizada para registrar movimentações de insumos no sistema.

---

### 6. Erro ao realizar movimentações

Ao tentar realizar qualquer movimentação na tela **“Retirada & Scanner QR”**, o sistema exibe uma mensagem de erro relacionada ao Supabase.

Mensagem apresentada:

`Erro Supabase ao registrar baixa: null value in column "id_status" of relation "movimentacoes" violates not-null constraint`

Esse erro impede que a movimentação seja registrada corretamente.

O sistema deve permitir o registro da movimentação sem gerar erro, preenchendo corretamente os dados necessários na tabela de movimentações.

---

### 7. Ajuste visual no campo “Quantidade”

Na tela **“Retirada & Scanner QR”**, ao passar o cursor sobre o campo **“Quantidade”**, ocorre um problema visual no hover.

O cursor perde o contorno e fica totalmente branco, misturando-se com o fundo da tela.

Esse comportamento dificulta a visualização do cursor no campo e deve ser ajustado para manter contraste e legibilidade durante a interação do usuário.

---

## Catálogo Mestre

### 8. Adicionar paginação no Catálogo Mestre

Na tela **“Catálogo Mestre”**, quando houver mais de 10 insumos cadastrados, deve ser exibida paginação.

A paginação deve permitir a navegação entre os registros, evitando que a tela fique muito extensa ou com excesso de informações exibidas de uma só vez.

---

### 9. Filtrar insumos pelo departamento selecionado no header

Na tela **“Catálogo Mestre”**, a listagem de insumos deve respeitar o departamento selecionado no header.

Exemplo: se o departamento selecionado for **Marketing**, a tela deve exibir apenas os insumos vinculados ao departamento de Marketing.

Caso a opção **“Todos os departamentos”** esteja selecionada, o sistema deve exibir todos os insumos cadastrados, sem aplicar filtro por departamento.

---

## Relatórios e Auditoria

### 10. Botão “Gerar relatório de alerta” sem ação

Na tela **“Relatórios e Auditoria”**, o botão **“Gerar relatório de alerta”** não está executando nenhuma ação ao ser clicado.

O botão deve executar a função esperada, gerando o relatório correspondente ou exibindo uma mensagem adequada caso não existam dados disponíveis.

---

### 11. Exportação em CSV / Excel não está funcionando

Na tela **“Relatórios e Auditoria”**, a função **“Exportar em CSV / Excel”** não está funcionando corretamente.

Ao tentar exportar o relatório, o sistema retorna a seguinte mensagem de erro:

`Biblioteca SheetJS (XLSX) não foi carregada.`

A exportação deve funcionar corretamente, permitindo gerar e baixar o arquivo em CSV ou Excel conforme esperado.