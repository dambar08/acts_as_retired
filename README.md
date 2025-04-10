# ActsAsRetired

[![CI](https://github.com/dambar08/acts_as_retired/actions/workflows/ruby.yml/badge.svg)](https://github.com/dambar08/acts_as_retired/actions/workflows/ruby.yml)

A Rails plugin to add soft retire.

This gem can be used to hide records instead of deleting them, making them
recoverable later.

## Support

**This version targets Rails 6.1+ and Ruby 3.0+ only**

If you're working with Rails 6.0 and earlier, or with Ruby 2.7 or earlier,
please require an older version of the `acts_as_retired` gem.

### Known issues

* Using `acts_as_retired` and ActiveStorage on the same model
  [leads to a SystemStackError](https://github.com/ActsAsRetired/acts_as_retired/issues/103).
* You cannot directly create a model in a retired state, or update a model
  after it's been retired.

## Usage

#### Install gem

```ruby
gem "acts_as_retired", "~> 0.10.3"
```

```shell
bundle install
```

#### Create migration

```shell
bin/rails generate migration AddRetiredAtToRetirec retired_at:datetime:index
```

#### Enable ActsAsRetired

```ruby
class Retirec < ActiveRecord::Base
  acts_as_retired
end
```

By default, ActsAsRetired assumes a record's *deletion* is stored in a
`datetime` column called `retired_at`.

### Options

If you are using a different column name and type to store a record's
*deletion*, you can specify them as follows:

- `column:      'retired'`
- `column_type: 'boolean'`

While *column* can be anything (as long as it exists in your database), *type*
is restricted to:

- `boolean`
- `time` or
- `string`

Note that the `time` type corresponds to the database column type `datetime`
in your Rails migrations and schema.

If your column type is a `string`, you can also specify which value to use when
marking an object as retired by passing `:deleted_value` (default is
"retired"). Any records with a non-matching value in this column will be
treated normally, i.e., as not retired.

If your column type is a `boolean`, it is possible to specify `allow_nulls`
option which is `true` by default. When set to `false`, entities that have
`false` value in this column will be considered not retired, and those which
have `true` will be considered retired. When `true` everything that has a
not-null value will be considered retired.

### Filtering

If a record is retired by ActsAsRetired, it won't be retrieved when accessing
the database.

So, `Retirec.all` will **not** include the **retired records**.

When you want to access them, you have 2 choices:

```ruby
Retirec.only_retired # retrieves only the retired records
Retirec.with_retired # retrieves all records, retired or not
```

When using the default `column_type` of `'time'`, the following extra scopes
are provided:

```ruby
time = Time.now

Retirec.retired_after_time(time)
Retirec.retired_before_time(time)

# Or roll it all up and get a nice window:
Retirec.deleted_inside_time_window(time, 2.minutes)
```

### Real deletion

In order to really delete a record, just use:

```ruby
retirec.retire_fully!
Retirec.retire_all!(conditions)
```

### Recovery

Recovery is easy. Just invoke `recover` on it, like this:

```ruby
Retirec.only_retired.where("name = ?", "not dead yet").first.recover
```

All associations marked as `dependent: :destroy` are also recursively recovered.

If you would like to disable this behavior, you can call `recover` with the
`recursive` option:

```ruby
Retirec.only_retired.where("name = ?", "not dead yet").first.recover(recursive: false)
```

If you would like to change this default behavior for one model, you can use
the `recover_dependent_associations` option

```ruby
class Retirec < ActiveRecord::Base
  acts_as_retired recover_dependent_associations: false
end
```

By default, dependent records will be recovered if they were retired within 2
minutes of the object upon which they depend.

This restores the objects to the state before the recursive deletion without
restoring other objects that were retired earlier.

The behavior is only available when both parent and dependant are using
timestamp fields to mark deletion, which is the default behavior.

This window can be changed with the `dependent_recovery_window` option:

```ruby
class Retirec < ActiveRecord::Base
  acts_as_retired
  has_many :paranoids, dependent: :destroy
end

class Paranoid < ActiveRecord::Base
  belongs_to :paranoic

  # Paranoid objects will be recovered alongside Paranoic objects
  # if they were retired within 10 minutes of the Paranoic object
  acts_as_retired dependent_recovery_window: 10.minutes
end
```

or in the recover statement

```ruby
Retirec.only_retired.where("name = ?", "not dead yet").first
  .recover(recovery_window: 30.seconds)
```

### recover!

You can invoke `recover!` if you wish to raise an error if the recovery fails.
The error generally stems from ActiveRecord.

```ruby
Retirec.only_retired.where("name = ?", "not dead yet").first.recover!
# => ActiveRecord::RecordInvalid: Validation failed: Name already exists
```

Optionally, you may also raise the error by passing `raise_error: true` to the
`recover` method. This behaves the same as `recover!`.

```ruby
Retirec.only_retired.where("name = ?", "not dead yet").first.recover(raise_error: true)
```

### Validation

ActiveRecord's built-in uniqueness validation does not account for records
retired by ActsAsRetired. If you want to check for uniqueness among
non-retired records only, use the macro `validates_as_paranoid` in your model.
Then, instead of using `validates_uniqueness_of`, use
`validates_uniqueness_of_without_deleted`. This will keep retired records from
counting against the uniqueness check.

```ruby
class Retirec < ActiveRecord::Base
  acts_as_retired
  validates_as_paranoid
  validates_uniqueness_of_without_deleted :name
end

p1 = Retirec.create(name: 'foo')
p1.destroy

p2 = Retirec.new(name: 'foo')
p2.valid? #=> true
p2.save

p1.recover #=> fails validation!
```

### Status

A paranoid object could be retired or destroyed fully.

You can check if the object is retired with the `retired?` helper

```ruby
Retirec.create(name: 'foo').destroy
Retirec.with_retired.first.retired? #=> true
```

After the first call to `.destroy` the object is `retired?`.

You can check if the object is fully destroyed with `destroyed_fully?` or `deleted_fully?`.

```ruby
Retirec.create(name: 'foo').destroy
Retirec.with_retired.first.retired? #=> true
Retirec.with_retired.first.destroyed_fully? #=> false
p1 = Retirec.with_retired.first
p1.destroy # this fully destroys the object
p1.destroyed_fully? #=> true
p1.deleted_fully? #=> true
```

### Scopes

As you've probably guessed, `with_retired` and `only_retired` are scopes. You
can, however, chain them freely with other scopes you might have.

For example:

```ruby
Retirec.pretty.with_retired
```

This is exactly the same as:

```ruby
Retirec.with_retired.pretty
```

You can work freely with scopes and it will just work:

```ruby
class Retirec < ActiveRecord::Base
  acts_as_retired
  scope :pretty, where(pretty: true)
end

Retirec.create(pretty: true)

Retirec.pretty.count #=> 1
Retirec.only_retired.count #=> 0
Retirec.pretty.only_retired.count #=> 0

Retirec.first.destroy

Retirec.pretty.count #=> 0
Retirec.only_retired.count #=> 1
Retirec.pretty.only_retired.count #=> 1
```

### Associations

Associations are also supported.

From the simplest behaviors you'd expect to more nifty things like the ones
mentioned previously or the usage of the `:with_retired` option with
`belongs_to`

```ruby
class Parent < ActiveRecord::Base
  has_many :children, class_name: "RetirecChild"
end

class RetirecChild < ActiveRecord::Base
  acts_as_retired
  belongs_to :parent

  # You may need to provide a foreign_key like this
  belongs_to :parent_including_deleted, class_name: "Parent",
    foreign_key: 'parent_id', with_retired: true
end

parent = Parent.first
child = parent.children.create
parent.destroy

child.parent #=> nil
child.parent_including_deleted #=> Parent (it works!)
```

### Callbacks

There are couple of callbacks that you may use when dealing with deletion and
recovery of objects. There is `before_recover` and `after_recover` which will
be triggered before and after the recovery of an object respectively.

Default ActiveRecord callbacks such as `before_destroy` and `after_destroy` will
be triggered around `.retire!` and `.destroy_fully!`.

```ruby
class Retirec < ActiveRecord::Base
  acts_as_retired

  before_recover :set_counts
  after_recover :update_logs
end
```

## Caveats

Watch out for these caveats:

- You cannot use scopes named `with_retired` and `only_retired`
- You cannot use scopes named `deleted_inside_time_window`,
  `retired_before_time`, `retired_after_time` **if** your paranoid column's
  type is `time`
- You cannot name association `*_with_retired`
- `unscoped` will return all records, retired or not

See `LICENSE`.
