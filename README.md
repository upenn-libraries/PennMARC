# Penn Libraries MARC Parser

This gem embodies the received and newfound wisdom of Penn Libraries MARC parsing practice. The values returned by this
parser should be agnostic about the particular discovery system in which it is included. Most of this was extracted from
the "Nouveau Franklin" project aka [discovery_app](https://gitlab.library.upenn.edu/franklin/discovery-app).

When included in a project, it should be utilized like this:

```ruby
parser = PennMARC::Parser.new # eventually we will pass in some mappings...
puts parser.title_show(marc_record) # Title intended for display
```

All methods will require a `MARC::Record` object. For more about these, see the 
[ruby-marc](https://github.com/ruby-marc/ruby-marc) gem documentation

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

1. Update the version in `pennmarc.gemspec`
2. Run `gem build pennmarc.gemspec` with the latest code
3. Run `gem push pennmarc-{version number here}.gem`(e.g. `gem push pennmarc-1.0.0.gem`) to push to RubyGems. You will need access and MFA setup with RubyGems.

## QA

### Checking output of an arbitrary MARC XML file

TODO

```bash
MARC_FILE=path/to/marc.xml bundle exec rake pennmarc:parse
```

## TODO
 - rake task or some similar command to return a full set of values extracted from a specified marcxml file
 - Pipeline to run tests and publish to Rubygems
    - rubocop check
    - rdoc/yard coverage checks?
