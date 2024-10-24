# Airbyte

[install documentation](https://docs.airbyte.com/using-airbyte/getting-started/oss-quickstart)

```bash
curl -LsfS https://get.airbyte.com | bash -
# Install in low resource mode
abctl local install --low-resource-mode --port 8005  # by default is 8000, but it is used by Nginx
abctl local credentials  # get credentials and password
  INFO    Using Kubernetes provider:
            Provider: kind
            Kubeconfig: /home/ubuntu-user1/.airbyte/abctl/abctl.kubeconfig
            Context: kind-airbyte-abctl
 SUCCESS  Retrieving your credentials from 'airbyte-auth-secrets'
  INFO    Credentials:
            Email: dst_airlines@mail.com
            Password: BivUGK17vTE4AFXvSLDoDQUBJBuWrOZU
            Client-Id: 2e8b230a-2ec9-484f-9716-58d80091db60
            Client-Secret: U5E0sMALzsXnzWkMTkKHwuoleKOAfy7v
# Uninstalling because i can not use it
abctl local uninstall
```