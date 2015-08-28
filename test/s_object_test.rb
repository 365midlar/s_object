require 'test_helper'

class SObjectTest < Minitest::Test

  # mapping a simple object

  class TestObject < SObject::SObject
    maps_object('TestObject')
    maps_standard_field(:my_field1, :MyField1)
    maps_custom_field(:my_field2, :MyField2)
  end

  class NewTestObject < SObject::SObject
    maps_custom_object('NewTestObject', api_name: 'TestObject2')
  end

  # mapping relationships

  class Child < SObject::SObject
    maps_object('Child')
    maps_parent(:parent, class: :'SObjectTest::Parent')
  end

  class Parent < SObject::SObject
    maps_object('Parent')
    maps_children(:children, class: :'SObjectTest::Child')
  end

  def test_that_it_has_a_version_number
    refute_nil ::SObject::VERSION
  end

  # object mapping

  def test_sobject_api_name
    assert_respond_to NewTestObject, :s_object_api_name
    assert_equal 'TestObject2__c', NewTestObject.s_object_api_name
    assert_equal 'NewTestObject', NewTestObject.s_object_name
  end

  # field mapping

  def test_sobject_name_tracking
    assert_respond_to TestObject.new, :external_id
  end

  def test_basic_field_mapping
    assert_equal TestObject.remote_fields[:MyField1], :my_field1
    assert_equal TestObject.local_fields[:my_field1], :MyField1
  end

  def test_external_id_has_restricted_length
    assert_equal TestObject.new(external_id: '123456789012345678').external_id, '123456789012345'
    assert_equal TestObject.new({ Id: '123456789012345678' }, { translate: true }).external_id, '123456789012345'
  end

  def test_all_mapped_fields_with_values_in_attributes
    attributes = { external_id: 'somefakeid', my_field1: 'foo', my_field2: 'bar' }
    assert_equal TestObject.new(attributes).attributes, attributes
  end

  def test_field_assignment_on_init_with_symbols
    attributes = { external_id: 'somefakeid', my_field1: 'foo', my_field2: 'bar' }
    obj = TestObject.new
    obj.assign_attributes(attributes)
    assert_equal attributes, obj.attributes
  end

  def test_field_assignment_on_init_with_strings
    attributes = { external_id: 'somefakeid', my_field1: 'foo', my_field2: 'bar' }
    str_attributes = { 'external_id' => 'somefakeid', 'my_field1' => 'foo', 'my_field2' => 'bar' }
    obj = TestObject.new
    obj.assign_attributes(str_attributes)
    assert_equal attributes, obj.attributes
  end

  # saving

  def test_field_translation_when_creating_from_remote_source
    obj = TestObject.build({Id: 'somefakeid'}, translate: true)
    assert_equal obj.external_id, 'somefakeid'
  end

  def test_usage_of_remote_attributes_when_updating
    TestObject.stubs(:client).returns(stub(update!: true))
    obj = TestObject.new({external_id: 'somefakeid'})
    obj.expects(:remote_attributes)
    obj.update!({my_field1: 'myvalue'})
    obj.attributes({external_id: 'somefakeid', my_field1: 'myvalue', my_field2: nil})
  end

  def test_usage_of_remote_attributes_when_creating
    TestObject.stubs(:client).returns(stub(create!: 'somefakeid'))
    obj = TestObject.create!({my_field1: 'myvalue'})
    attributes = {external_id: 'somefakeid', my_field1: 'myvalue', my_field2: nil}
    assert_equal attributes, obj.attributes
  end

  # querying

  def test_construction_of_single_value_where_conditions
    query = TestObject.where_conditions(my_field1: 'foo', my_field2: 'bar')
    assert_equal "MyField1 = 'foo' AND Test__MyField2__c = 'bar'", query
  end

  def test_construction_of_multi_value_where_conditions
    query = TestObject.where_conditions(my_field1: 'foo', my_field2: 'bar')
    assert_equal "MyField1 = 'foo' AND Test__MyField2__c = 'bar'", query
  end

  def test_argument_checking_for_construction_of_where_conditions
    assert_raises ArgumentError do
      TestObject.where_conditions(invalid_field: 'foo')
    end
  end

  def test_local_attribute_translation_for_received_values
    TestObject.stubs(:client).returns(stub(find: {Id: 'somefakeid'}))
    obj = TestObject.find('somefakeid')
    assert_equal 'somefakeid', obj.external_id
  end

  def test_lazy_loading_of_parent_on_attribute_call
    child = Child.new({parent_id: 'somefakeid'})

    # mock the client call to the parent object
    Parent.stubs(:client).returns(stub(find: {Id: 'somefakeid'}))

    parent = child.parent
    assert_equal Parent, parent.class
    assert_equal 'somefakeid', parent.external_id
  end

  def test_lazy_loading_of_children_on_attribute_call
    parent = Parent.new({external_id: 'somefakeid'})
    assert_equal SObject::SObjectCollectionProxy, parent.children.class
  end

  def test_remote_id_fields_in_attribute_collection_on_demand_only
    child = Child.new
    refute_includes child.attributes.keys, :parent_id
  end
end
