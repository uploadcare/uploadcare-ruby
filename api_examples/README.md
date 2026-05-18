# API Examples

Each file in this directory maps to one documented Uploadcare API endpoint.

Run examples with project-managed Ruby and real credentials:

```bash
mise exec -- ruby api_examples/rest_api/get_project.rb
mise exec -- ruby api_examples/upload_api/post_base.rb
```

Required environment variables:

- `UPLOADCARE_PUBLIC_KEY`
- `UPLOADCARE_SECRET_KEY`

Optional environment variables:

- `UPLOADCARE_AUTH_TYPE`
- `UPLOADCARE_REMOTE_STORAGE` for `post_files_remote_copy.rb`

Verification:

- Verified against a real Uploadcare demo account on `2026-03-16`
- All canonical scripts in `api_examples/rest_api` and `api_examples/upload_api` executed successfully

## REST API 0.7

| Endpoint | Example file | Notes |
| --- | --- | --- |
| `GET /files/` | `api_examples/rest_api/get_files.rb` | Uses `client.files.list` |
| `PUT /files/{uuid}/storage/` | `api_examples/rest_api/put_files_uuid_storage.rb` | Uses `file.store` |
| `DELETE /files/{uuid}/storage/` | `api_examples/rest_api/delete_files_uuid_storage.rb` | Uses `file.delete` |
| `GET /files/{uuid}/` | `api_examples/rest_api/get_files_uuid.rb` | Uses `client.files.find` |
| `PUT /files/storage/` | `api_examples/rest_api/put_files_storage.rb` | Uses `client.files.batch_store` |
| `DELETE /files/storage/` | `api_examples/rest_api/delete_files_storage.rb` | Uses `client.files.batch_delete` |
| `POST /files/local_copy/` | `api_examples/rest_api/post_files_local_copy.rb` | Uses `client.files.copy_to_local` |
| `POST /files/remote_copy/` | `api_examples/rest_api/post_files_remote_copy.rb` | Uses `client.files.copy_to_remote`; requires `UPLOADCARE_REMOTE_STORAGE` |
| `GET /files/{uuid}/metadata/` | `api_examples/rest_api/get_files_uuid_metadata.rb` | Uses `client.file_metadata.index` |
| `GET /files/{uuid}/metadata/{key}/` | `api_examples/rest_api/get_files_uuid_metadata_key.rb` | Uses `client.file_metadata.show` |
| `PUT /files/{uuid}/metadata/{key}/` | `api_examples/rest_api/put_files_uuid_metadata_key.rb` | Uses `client.file_metadata.update` |
| `DELETE /files/{uuid}/metadata/{key}/` | `api_examples/rest_api/delete_files_uuid_metadata_key.rb` | Uses `client.file_metadata.delete` |
| `GET /groups/` | `api_examples/rest_api/get_groups.rb` | Uses `client.groups.list` |
| `GET /groups/{uuid}/` | `api_examples/rest_api/get_groups_uuid.rb` | Uses `client.groups.find` |
| `DELETE /groups/{uuid}/` | `api_examples/rest_api/delete_groups_uuid.rb` | Uses `group.delete` |
| `POST /addons/aws_rekognition_detect_labels/execute/` | `api_examples/rest_api/post_addons_aws_rekognition_detect_labels_execute.rb` | Uses `client.addons.aws_rekognition_detect_labels` |
| `GET /addons/aws_rekognition_detect_labels/execute/status/` | `api_examples/rest_api/get_addons_aws_rekognition_detect_labels_execute_status.rb` | Uses `client.addons.*` and checks status |
| `POST /addons/aws_rekognition_detect_moderation_labels/execute/` | `api_examples/rest_api/post_addons_aws_rekognition_detect_moderation_labels_execute.rb` | Uses `client.addons.aws_rekognition_detect_moderation_labels` |
| `GET /addons/aws_rekognition_detect_moderation_labels/execute/status/` | `api_examples/rest_api/get_addons_aws_rekognition_detect_moderation_labels_execute_status.rb` | Uses `client.addons.*` and checks status |
| `POST /addons/uc_clamav_virus_scan/execute/` | `api_examples/rest_api/post_addons_uc_clamav_virus_scan_execute.rb` | Uses `client.addons.uc_clamav_virus_scan` |
| `GET /addons/uc_clamav_virus_scan/execute/status/` | `api_examples/rest_api/get_addons_uc_clamav_virus_scan_execute_status.rb` | Uses `client.addons.*` and checks status |
| `POST /addons/remove_bg/execute/` | `api_examples/rest_api/post_addons_remove_bg_execute.rb` | Uses `client.addons.remove_bg` |
| `GET /addons/remove_bg/execute/status/` | `api_examples/rest_api/get_addons_remove_bg_execute_status.rb` | Uses `client.addons.*` and checks status |
| `GET /project/` | `api_examples/rest_api/get_project.rb` | Uses `client.project.current` |
| `GET /webhooks/` | `api_examples/rest_api/get_webhooks.rb` | Uses `client.webhooks.list` |
| `POST /webhooks/` | `api_examples/rest_api/post_webhooks.rb` | Uses `client.webhooks.create` |
| `PUT /webhooks/{id}/` | `api_examples/rest_api/put_webhooks_id.rb` | Uses `client.webhooks.update` |
| `DELETE /webhooks/unsubscribe/` | `api_examples/rest_api/delete_webhooks_unsubscribe.rb` | Uses `client.webhooks.delete` |
| `GET /convert/document/{uuid}/` | `api_examples/rest_api/get_convert_document_uuid.rb` | Uses `client.conversions.documents.info` |
| `POST /convert/document/` | `api_examples/rest_api/post_convert_document.rb` | Uses `client.conversions.documents.convert` |
| `GET /convert/document/status/{token}/` | `api_examples/rest_api/get_convert_document_status_token.rb` | Uses `client.conversions.documents.convert` then `status` |
| `POST /convert/video/` | `api_examples/rest_api/post_convert_video.rb` | Uses `client.conversions.videos.convert` |
| `GET /convert/video/status/{token}/` | `api_examples/rest_api/get_convert_video_status_token.rb` | Uses `client.conversions.videos.convert` then `status` |

## Upload API

| Endpoint | Example file | Notes |
| --- | --- | --- |
| `POST /base/` | `api_examples/upload_api/post_base.rb` | Uses raw upload API |
| `POST /multipart/start/` | `api_examples/upload_api/post_multipart_start.rb` | Starts and completes a real multipart upload |
| `PUT <presigned-url-x>` | `api_examples/upload_api/put_multipart_part.rb` | Uploads one part via gem multipart helper |
| `POST /multipart/complete/` | `api_examples/upload_api/post_multipart_complete.rb` | Completes a real multipart upload |
| `POST /from_url/` | `api_examples/upload_api/post_from_url.rb` | Uses raw upload API |
| `GET /from_url/status/` | `api_examples/upload_api/get_from_url_status.rb` | Starts async upload then checks status |
| `GET /info/` | `api_examples/upload_api/get_info.rb` | Uses raw upload API |
| `POST /group/` | `api_examples/upload_api/post_group.rb` | Uses raw upload API |
| `GET /group/info/` | `api_examples/upload_api/get_group_info.rb` | Uses raw upload API |
