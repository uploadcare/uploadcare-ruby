# Upgrade notes

## v1.* -> v2.*

In 2.* release we've moved to [REST API v0.5][uploadcare-changelog-rest-api-v05] which introduces a new pagination for `/files/` and `/groups/` endpoints, so `Uploadcare::Api::FileList` and `Uploadcare::Api::GroupList` were completely reimplemented. 

Previously, the file/group list API was:

```ruby
# creating
list = api.file_list # => #<Uploadcare::Api::FileList page=1 ...>

# accessing files/groups
list.results # => [#<Uploadcare::Api::File>, ...]

# pagination
list.next_page # => #<Uploadcare::Api::FileList page=2 ...>
list.previous_page # => #<Uploadcare::Api::FileList page=1 ...>
list.go_to 5 # => #<Uploadcare::Api::FileList page=5 ...>

# metadata
list.pages # => 15
list.page # => 5
list.total # => 308 (files in a project)
```

It **won't work anymore**. For the details on the new file/group lists interface see [readme][readme]

The core features of the new file/group list API are: 

- transparent pagination via enumerable interface
- loading objects on demand
- ordering, filtering and slicing

[uploadcare-changelog-rest-api-v05]: https://uploadcare.com/changelog/tag/rest-api#rest-api-version-05
[readme]: https://github.com/uploadcare/uploadcare-ruby#file-lists
