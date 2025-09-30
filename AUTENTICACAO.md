# 🔐 Sistema de Autenticação NOVA

## Como Funciona o Processo de Autenticação

### **1. Fluxo de Autenticação**

```
Tela de Boas-vindas → Tela de Login → Dashboard
        ↑                    ↓
        ←── Logout ←─────────┘
```

### **2. Usuários Pré-cadastrados**

O sistema vem com 3 usuários de exemplo:

| Email | Senha | Nome |
|-------|-------|------|
| `admin@nova.com` | `123456` | Administrador |
| `lojista@nova.com` | `lojista123` | Lojista |
| `teste@nova.com` | `teste123` | Usuário Teste |

### **3. Funcionalidades Implementadas**

#### **✅ Login**
- Validação de email e senha
- Verificação de credenciais locais
- Feedback visual de erro/sucesso
- Redirecionamento automático para dashboard

#### **✅ Logout**
- Botão de logout no menu do dashboard
- Confirmação antes de sair
- Limpeza de dados de sessão
- Redirecionamento para tela de boas-vindas

#### **✅ Persistência de Sessão**
- Verificação automática ao abrir o app
- Se já estiver logado, vai direto para o dashboard
- Se não estiver logado, vai para tela de boas-vindas

#### **✅ Recuperação de Senha**
- Modal para inserir email
- Simulação de envio de instruções
- Feedback de sucesso/erro

### **4. Armazenamento Local**

- **SharedPreferences**: Armazena status de login e dados do usuário
- **Dados persistentes**: Produtos e vendas salvos localmente
- **Funcionamento offline**: 100% local, sem necessidade de internet

### **5. Estrutura de Arquivos**

```
lib/
├── services/
│   ├── auth_service.dart          # Lógica de autenticação
│   └── local_storage_service.dart # Armazenamento local
├── screens/
│   ├── welcome_screen.dart        # Tela inicial
│   ├── login_screen.dart          # Tela de login
│   └── dashboard_screen.dart      # Dashboard principal
└── main.dart                      # Verificação de autenticação
```

### **6. Como Testar**

1. **Execute o app**: `flutter run`
2. **Teste o login** com um dos usuários acima
3. **Navegue pelo dashboard** e teste as funcionalidades
4. **Teste o logout** pelo menu do dashboard
5. **Reabra o app** - deve ir direto para o dashboard se ainda estiver logado

### **7. Segurança Local**

- Senhas armazenadas em memória (não persistidas)
- Dados de sessão criptografados pelo SharedPreferences
- Validação de entrada em todos os formulários
- Limpeza automática de dados ao fazer logout

### **8. Próximos Passos (Opcionais)**

Para um sistema mais robusto, você pode implementar:

- **Criptografia** de senhas com hash
- **Biometria** (impressão digital/face)
- **Sincronização** com servidor remoto
- **Múltiplos usuários** com permissões diferentes
- **Backup** automático de dados

---

## 🚀 **Sistema Pronto para Uso!**

O NOVA está completamente funcional localmente, sem necessidade de backend ou internet. Todos os dados são salvos no dispositivo e persistem entre sessões.
