
# 如何访问K8S中的服务
![image](https://i.imgur.com/UYvC8Il.png)
# Ingress 介绍

Kubernetes 暴露服务的方式目前只有三种：LoadBlancer Service、NodePort Service、Ingress；前两种估计都应该很熟悉，具体的可以参考下 [这篇文](https://mritd.me/2016/12/06/try-traefik-on-kubernetes//)章；下面详细的唠一下这个 Ingress

# Ingress 是个什么玩意

可能从大致印象上 Ingress 就是能利用 Nginx、Haproxy 啥的负载均衡器暴露集群内服务的工具；那么问题来了，集群内服务想要暴露出去面临着几个问题：
- #### Pod 漂移问题

    众所周知 Kubernetes 具有强大的副本控制能力，能保证在任意副本(Pod)挂掉时自动从其他机器启动一个新的，还可以动态扩容等，总之一句话，这个 Pod 可能在任何时刻出现在任何节点上，也可能在任何时刻死在任何节点上；那么自然随着 Pod 的创建和销毁，Pod IP 肯定会动态变化；那么如何把这个动态的 Pod IP 暴露出去？这里借助于 Kubernetes 的 Service 机制，Service 可以以标签的形式选定一组带有指定标签的 Pod，并监控和自动负载他们的 Pod IP，那么我们向外暴露只暴露 Service IP 就行了；这就是 NodePort 模式：即在每个节点上开起一个端口，然后转发到内部 Service IP 上，如下图所示
    
    ![image](https://i.imgur.com/4Sc7zCj.jpg)
- #### 端口管理问题
    采用 NodePort 方式暴露服务面临一个坑爹的问题是，服务一旦多起来，NodePort 在每个节点上开启的端口会及其庞大，而且难以维护；这时候引出的思考问题是 “能不能使用 Nginx 啥的只监听一个端口，比如 80，然后按照域名向后转发？” 这思路很好，简单的实现就是使用 DaemonSet 在每个 node 上监听 80，然后写好规则，因为 Nginx 外面绑定了宿主机 80 端口(就像 NodePort)，本身又在集群内，那么向后直接转发到相应 Service IP 就行了，如下图所示
    ![image](https://i.imgur.com/eGRg6UN.jpg)

- #### 域名分配及动态更新问题
    从上面的思路，采用 Nginx 似乎已经解决了问题，但是其实这里面有一个很大缺陷：每次有新服务加入怎么改 Nginx 配置？总不能手动改或者来个 Rolling Update 前端 Nginx Pod 吧？这时候 “伟大而又正直勇敢的” Ingress 登场，如果不算上面的 Nginx，Ingress 只有两大组件：Ingress Controller 和 Ingress

    Ingress 这个玩意，简单的理解就是 你原来要改 Nginx 配置，然后配置各种域名对应哪个 Service，现在把这个动作抽象出来，变成一个 Ingress 对象，你可以用 yml 创建，每次不要去改 Nginx 了，直接改 yml 然后创建/更新就行了；那么问题来了：”Nginx 咋整？”

   Ingress Controller 这东西就是解决 “Nginx 咋整” 的；Ingress Controoler 通过与 Kubernetes API 交互，动态的去感知集群中 Ingress 规则变化，然后读取他，按照他自己模板生成一段 Nginx 配置，再写到 Nginx Pod 里，最后 reload 一下，工作流程如下图
   ![image](https://i.imgur.com/Ws2gBHl.jpg)
   
   当然在实际应用中，最新版本 Kubernetes 已经将 Nginx 与 Ingress Controller 合并为一个组件，所以 Nginx 无需单独部署，只需要部署 Ingress Controller 即可。

# 怼一个 Nginx Ingress   

上面啰嗦了那么多，只是为了讲明白 Ingress 的各种理论概念，下面实际部署很简单


### 配置 ingress RBAC 

    cat nginx-ingress-controller-rbac.yml
    #apiVersion: v1
    #kind: Namespace
    #metadata:
    #  name: kube-system
    ---
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: nginx-ingress-serviceaccount
      namespace: kube-system
    ---
    apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: ClusterRole
    metadata:
      name: nginx-ingress-clusterrole
    rules:
      - apiGroups:
          - ""
        resources:
          - configmaps
          - endpoints
          - nodes
          - pods
          - secrets
        verbs:
          - list
          - watch
      - apiGroups:
          - ""
        resources:
          - nodes
        verbs:
          - get
      - apiGroups:
          - ""
        resources:
          - services
        verbs:
          - get
          - list
          - watch
      - apiGroups:
          - "extensions"
        resources:
          - ingresses
        verbs:
          - get
          - list
          - watch
      - apiGroups:
          - ""
        resources:
            - events
        verbs:
            - create
            - patch
      - apiGroups:
          - "extensions"
        resources:
          - ingresses/status
        verbs:
          - update
    ---
    apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: Role
    metadata:
      name: nginx-ingress-role
      namespace: kube-system
    rules:
      - apiGroups:
          - ""
        resources:
          - configmaps
          - pods
          - secrets
          - namespaces
        verbs:
          - get
      - apiGroups:
          - ""
        resources:
          - configmaps
        resourceNames:
          # Defaults to "<election-id>-<ingress-class>"
          # Here: "<ingress-controller-leader>-<nginx>"
          # This has to be adapted if you change either parameter
          # when launching the nginx-ingress-controller.
          - "ingress-controller-leader-nginx"
        verbs:
          - get
          - update
      - apiGroups:
          - ""
        resources:
          - configmaps
        verbs:
          - create
      - apiGroups:
          - ""
        resources:
          - endpoints
        verbs:
          - get
          - create
          - update
    ---
    apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: RoleBinding
    metadata:
      name: nginx-ingress-role-nisa-binding
      namespace: kube-system
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: nginx-ingress-role
    subjects:
      - kind: ServiceAccount
        name: nginx-ingress-serviceaccount
        namespace: kube-system
    ---
    apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: ClusterRoleBinding
    metadata:
      name: nginx-ingress-clusterrole-nisa-binding
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: nginx-ingress-clusterrole
    subjects:
      - kind: ServiceAccount
        name: nginx-ingress-serviceaccount
        namespace: kube-system
### 部署默认后端

我们知道 前端的 Nginx 最终要负载到后端 service 上，那么如果访问不存在的域名咋整？官方给出的建议是部署一个 默认后端，对于未知请求全部负载到这个默认后端上；这个后端啥也不干，就是返回 404，部署如下

    kubectl create -f default-backend.yaml
    
这个 default-backend.yaml 文件可以在 github [Ingress 仓库](https://github.com/kubernetes/ingress-nginx/tree/master) 找到. 针对官方配置 我们单独添加了 nodeselector 指定，绑定LB地址 以方便DNS 做解析。

    cat default-backend.yaml
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: default-http-backend
      labels:
        k8s-app: default-http-backend
      namespace: kube-system
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            k8s-app: default-http-backend
        spec:
          terminationGracePeriodSeconds: 60
          containers:
          - name: default-http-backend
            # Any image is permissable as long as:
            # 1. It serves a 404 page at /
            # 2. It serves 200 on a /healthz endpoint
            image: harbor-demo.dianrong.com/kubernetes/defaultbackend:1.0
            livenessProbe:
              httpGet:
                path: /healthz
                port: 8080
                scheme: HTTP
              initialDelaySeconds: 30
              timeoutSeconds: 5
            ports:
            - containerPort: 8080
            resources:
              limits:
                cpu: 10m
                memory: 20Mi
              requests:
                cpu: 10m
                memory: 20Mi
          nodeSelector:
            kubernetes.io/hostname: 172.16.200.209
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: default-http-backend
      namespace: kube-system
      labels:
        k8s-app: default-http-backend
    spec:
      ports:
      - port: 80
        targetPort: 8080
      selector:
        k8s-app: default-http-backend

### 部署 Ingress Controller       

部署完了后端就得把最重要的组件 Nginx+Ingres Controller(官方统一称为 Ingress Controller) 部署上

    kubectl create -f nginx-ingress-controller.yaml

注意： 官方的 Ingress Controller 有个坑，默认注释了hostNetwork 工作方式。以防止端口的在宿主机的冲突。没有绑定到宿主机 80 端口，也就是说前端 Nginx 没有监听宿主机 80 端口(这还玩个卵啊)；所以需要把配置搞下来自己加一下 hostNetwork

     cat  nginx-ingress-controller.yaml
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: nginx-ingress-controller
      labels:
        k8s-app: nginx-ingress-controller
      namespace: kube-system
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            k8s-app: nginx-ingress-controller
        spec:
          # hostNetwork makes it possible to use ipv6 and to preserve the source IP correctly regardless of docker configuration
          # however, it is not a hard dependency of the nginx-ingress-controller itself and it may cause issues if port 10254 already is taken on the host
          # that said, since hostPort is broken on CNI (https://github.com/kubernetes/kubernetes/issues/31307) we have to use hostNetwork where CNI is used
          # like with kubeadm
          # hostNetwork: true
          terminationGracePeriodSeconds: 60
          hostNetwork: true
          serviceAccountName: nginx-ingress-serviceaccount
          containers:
          - image: harbor-demo.dianrong.com/kubernetes/nginx-ingress-controller:0.9.0-beta.1
            name: nginx-ingress-controller
            readinessProbe:
              httpGet:
                path: /healthz
                port: 10254
                scheme: HTTP
            livenessProbe:
              httpGet:
                path: /healthz
                port: 10254
                scheme: HTTP
              initialDelaySeconds: 10
              timeoutSeconds: 1
            ports:
            - containerPort: 80
              hostPort: 80
            - containerPort: 443
              hostPort: 443
            env:
              - name: POD_NAME
                valueFrom:
                  fieldRef:
                    fieldPath: metadata.name
              - name: POD_NAMESPACE
                valueFrom:
                  fieldRef:
                    fieldPath: metadata.namespace
            args:
            - /nginx-ingress-controller
            - --default-backend-service=$(POD_NAMESPACE)/default-http-backend
    #        - --default-ssl-certificate=$(POD_NAMESPACE)/ingress-secret
          nodeSelector:
            kubernetes.io/hostname: 172.16.200.102

### 部署 Ingress

从上面可以知道 Ingress 就是个规则，指定哪个域名转发到哪个 Service，所以说首先我们得有个 Service，当然 Service 去哪找这里就不管了；这里默认为已经有了两个可用的 Service，以下以 Dashboard 为例

先写一个 Ingress 文件，语法格式啥的请参考 官方文档，由于我的 Dashboard 都在kube-system 这个命名空间，所以要指定 namespace.

    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: dashboard-ingress
      namespace: kube-system
      annotations:
        kubernetes.io/ingress.class: "nginx"
    spec:
      rules:
      - host: fox-dashboard.dianrong.com
        http:
          paths:
          - backend:
              serviceName: kubernetes-dashboard
              servicePort: 80

装逼成功截图如下
![image](https://i.imgur.com/AmVOgxK.png)


### 部署 Ingress TLS

上面已经搞定了 Ingress，下面就顺便把 TLS 怼上；官方给出的样例很简单，大致步骤就两步：创建一个含有证书的 secret、在 Ingress 开启证书；但是我不得不喷一下，文档就提那么一嘴，大坑一堆，比如多域名配置，TLS功能的启动都没。启用tls 需要在 nginx-ingress-controller添加参数，上面的controller以配置好。

    --default-ssl-certificate=$(POD_NAMESPACE)/ingress-secret


### 证书格式转换
创建secret 需要使用你的证书文件，官方要求证书的编码需要使用base64。转换方法如下：

证书转换pem 格式：

    openssl x509 -inform DER -in cert/doamin.crt -outform PEM  -out cert/domain.pem
    
证书编码转换base64

    cat domain.crt | base64 > domain.crt.base64

### 创建 secret ,需要使用base64 编码格式证书。

    cat ingress-secret.yml
    apiVersion: v1
    data:
      tls.crt: LS0tLS1CRU
      tls.key: LS0tLS1CRU
    kind: Secret
    metadata:
      name: ingress-secret
      namespace: kube-system
    type: Opaque
    
其实这个配置比如证书转码啥的没必要手动去做，可以直接使用下面的命令创建，kubectl 将自动为我们完整格式的转换。

    kubectl create secret tls ingress-secret --key certs/ttlinux.com.cn-key.pem --cert certs/ttlinux.com.cn.pem

### 重新部署 Ingress
生成完成后需要在 Ingress 中开启 TLS，Ingress 修改后如下

     cat dashboard-ingress.yml
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: dashboard-ingress
      namespace: kube-system
      annotations:
        kubernetes.io/ingress.class: "nginx"
    spec:
      tls:
      - hosts:
        - fox-dashboard.dianrong.com
        secretName: ingress-secret
      rules:
      - host: fox-dashboard.dianrong.com
        http:
          paths:
          - backend:
              serviceName: kubernetes-dashboard
              servicePort: 80


注意：一个 Ingress 只能使用一个 secret(secretName 段只能有一个)，也就是说只能用一个证书，更直白的说就是如果你在一个 Ingress 中配置了多个域名，那么使用 TLS 的话必须保证证书支持该 Ingress 下所有域名；并且这个 secretName 一定要放在上面域名列表最后位置，否则会报错 did not find expected key 无法创建；同时上面的 hosts 段下域名必须跟下面的 rules 中完全匹配

更需要注意一点：之所以这里单独开一段就是因为有大坑；Kubernetes Ingress 默认情况下，当你不配置证书时，会默认给你一个 TLS 证书的，也就是说你 Ingress 中配置错了，比如写了2个 secretName、或者 hosts 段中缺了某个域名，那么对于写了多个 secretName 的情况，所有域名全会走默认证书；对于 hosts 缺了某个域名的情况，缺失的域名将会走默认证书，部署时一定要验证一下证书，不能 “有了就行”；更新 Ingress 证书可能需要等一段时间才会生效

最后重新部署一下即可

    kubectl delete -f dashboard-ingress.yml
    kubectl create -f dashboard-ingress.yml


部署 TLS 后 80 端口会自动重定向到 443，最终访问截图如下
![image](https://i.imgur.com/CXLDMHV.png)


### ingress 高级用法

![image](https://i.imgur.com/cZ6gqVi.png)

- lvs 反向代理到 物理nginx。完成https拆包，继承nginx所有功能
- nginx 反向代理到ingress-control。 ingress-control 有两种部署方式 。
    - ingress-control 使用nodePort 方式暴漏服务
    - ingress-control 使用hostNetwork 方式暴漏服务

#### 总结分析
1. ingress-control 在自己的所属的namespace=ingress, 是可以夸不同namespace提供反向代理服.
1. 如果需要提供夸NS 访问ingress，先给 ingress-control创建RBAC .
1. ingress-control 使用hostnetwork 模式 性能比使用service nodePort 性能好很多。因为hostnetwork 是直接获取pod 的IP？
