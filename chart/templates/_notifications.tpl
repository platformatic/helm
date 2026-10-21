{{- define "service.icc.notificationsEnv" -}}
- name: PLT_NOTIFICATIONS_ENABLED
  value: {{ .enable | toString | quote }}
- name: PLT_NOTIFICATIONS_PROVIDERS
  value: {{ join "," .providers | quote }}
- name: PLT_NOTIFICATIONS_MINIMUM_LEVEL
  value: {{ .minimum_level | quote }}
- name: PLT_NOTIFICATIONS_EXCLUDED_SERVICES
  value: {{ join "," .excluded_services | quote }}
- name: PLT_NOTIFICATIONS_EMAIL_FROM
  value: {{ .email.from | quote }}
- name: PLT_NOTIFICATIONS_EMAIL_TO
  value: {{ join "," .email.recipients | quote }}
- name: PLT_NOTIFICATIONS_SMTP_HOST
  value: {{ .email.smtp.host | quote }}
- name: PLT_NOTIFICATIONS_SMTP_PORT
  value: {{ .email.smtp.port | toString | quote }}
- name: PLT_NOTIFICATIONS_SMTP_SECURE
  value: {{ .email.smtp.secure | toString | quote }}
- name: PLT_NOTIFICATIONS_SMTP_REQUIRE_TLS
  value: {{ .email.smtp.require_tls | toString | quote }}
- name: PLT_NOTIFICATIONS_SMTP_USER
  valueFrom:
    secretKeyRef:
      name: icc-notifications
      key: smtp_user
- name: PLT_NOTIFICATIONS_SMTP_PASSWORD
  valueFrom:
    secretKeyRef:
      name: icc-notifications
      key: smtp_password
- name: PLT_NOTIFICATIONS_SLACK_TOKEN
  valueFrom:
    secretKeyRef:
      name: icc-notifications
      key: slack_token
- name: PLT_NOTIFICATIONS_SLACK_CHANNEL
  value: {{ .slack.channel | quote }}
{{- end -}}
