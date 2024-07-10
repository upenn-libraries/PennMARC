# Penn Libraries MARC Parser

This gem embodies the received and newfound wisdom of Penn Libraries MARC parsing practice. The values returned by this
parser should be agnostic about the particular discovery system in which it is included. Most of this was extracted from
the "Nouveau Franklin" project aka [discovery_app](https://gitlab.library.upenn.edu/franklin/discovery-app).

When included in a project, it should be utilized like this:

```ruby
parser = PennMARC::Parser.new
puts parser.title_show(marc_record) # Title intended for display
```

All methods will require a `MARC::Record` object. For more about these, see the 
[ruby-marc](https://github.com/ruby-marc/ruby-marc) gem documentation

## Term Overriding

This gem provides configuration as well as a method for overriding and removing terms that are undesirable. In your app,
you can remove or replace the configured terms like so:

```ruby
improved_values = PennMARC::HeadingControl.term_override(values)
```

This will remove any elements of the `values` array that include any terms defined in `mappers/headings_remove.yml` and
replace any terms defined in the `headings_override.yml` file.

By default, terms are replaced for `Subject#*show` and `Subject#facet` methods. You can bypass the default overriding on
on these methods by passing `override: false`.

## Development

### Requirements
- ruby 3.2.2, other versions will probably work

### Setup

After cloning the repository and setting up Ruby for the project, run `bundle install` to install the gems.

### Organization

Classes in the `helpers` directory bring together common fields that may share logic. `PennMARC::Util` holds methods 
used for common tasks such as joining subfields.

### Documentation

Highly descriptive and accurate documentation of MARC parsing practices will improve developer happiness, as well as 
that of library collaborators. To this end, developers should utilize
[YARD documentation syntax](https://rubydoc.info/gems/yard/file/docs/GettingStarted.md) as appropriate.

A YARD documentation server can be run during development and will reload with updated docs as you work:

```bash
yard server --reload
```

When successful, the documentation pages will be available at [http://localhost:8808](http://localhost:8808).

### Style

This gem utilizes the [upennlib-rubocop](https://gitlab.library.upenn.edu/dld/upennlib-rubocop) 
gem to enforce a consistent style.

To run rubocop with the configuration:

```bash
rubocop
```

#### To regenerate `.rubocop_todo.yml`:
```shell
bundle exec rubocop --auto-gen-config  --auto-gen-only-exclude --exclude-limit 10000
```


### Testing

Testing is done with `rspec`. Test coverage should approach 100% given the relative simplicity of this gem.

To run the test suite:

```bash
rspec
```

## Publishing the Gem

1. Update the `VERSION` constant in [lib/pennmarc/version.rb](lib/pennmarc/version.rb) following this gem's versioning pattern (ex 1.1.0).
2. Merge the change into `main`.
3. Create a Gitlab Release:
   1. Go to https://gitlab.library.upenn.edu/dld/catalog/pennmarc/-/releases/new
   2. Create a new tag that matches the version set in step 1 (ex: v1.1.0). 
   3. Add a release title that is the same as the tag name. 
   4. Submit by clicking "Create Release".
4. Once the release is created a pipeline will run to publish the gem to RubyGems. 

### Versioning Guidelines

We do not explicitly follow [Semantic Versioning](https://semver.org/) principles, but follow it's general principles. 
In common cases, here's what to do:

- Increment **MAJOR_VERSION** if the `Parser` class functionality is modified in a breaking fashion.
- Increment **MINOR_VERSION** if a `Helper` class is renamed, or if an existing helper method is renamed.
- Increment **PATCH_VERSION** if a new `Helper` class or method is added, of if any non-breaking bugfix is made.
