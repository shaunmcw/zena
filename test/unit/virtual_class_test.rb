# encoding: utf-8
require 'test_helper'

class VirtualClassTest < Zena::Unit::TestCase
  POST_PROPERTIES = %w{assigned cached_role_ids date info origin settings summary text title tz weight}
  NOTE_PROPERTIES = %w{assigned cached_role_ids info origin settings summary text title tz weight}
  
  def test_virtual_subclasse
    # add a sub class
    login(:lion)
    vclass = VirtualClass.create(:superclass => 'Post', :name => 'Super', :create_group_id => groups_id(:public))
    assert !vclass.new_record?
    assert_equal "NNPS", vclass.kpath
  end

  def test_node_classes_for_form
    login(:anon)
    # preload models
    [Project, Skin, Note, Image, Template]

    classes_for_form = Node.classes_for_form
    assert classes_for_form.include?(["Node", "Node"])
    assert classes_for_form.include?(["  Page", "Page"])
    assert classes_for_form.include?(["  Note", "Note"])
    assert classes_for_form.include?(["  Reference", "Reference"])
    assert classes_for_form.include?(["    Letter", "Letter"])
  end

  def test_note_classes_for_form
    login(:anon)
    # preload models
    [Project, Skin, Note, Image, Template]

    classes_for_form = Note.classes_for_form
    assert classes_for_form.include?(["Note", "Note"])
    assert classes_for_form.include?(["  Letter", "Letter"])
    assert classes_for_form.include?(["  Post", "Post"])
    classes_for_form.map!{|k,c| c}

    assert !classes_for_form.include?("Node")
    assert !classes_for_form.include?("Page")
    assert !classes_for_form.include?("Reference")
  end

  def test_post_classes_for_form
    # add a sub class
    login(:lion)
    vclass = VirtualClass.create(:superclass => 'Post', :name => 'Super', :create_group_id => groups_id(:public))
    assert !vclass.new_record?

    login(:anon)

    classes_for_form = Node.get_class('Post').classes_for_form
    assert classes_for_form.include?(["Post", "Post"])
    assert classes_for_form.include?(["  Super", "Super"])
    classes_for_form.map!{|k,c| c}
    assert !classes_for_form.include?("Node")
    assert !classes_for_form.include?("Note")
    assert !classes_for_form.include?("Letter")
    assert !classes_for_form.include?("Page")
    assert !classes_for_form.include?("Reference")
  end
  
  def test_sub_classes
    # add a sub class
    login(:lion)
    vclass = VirtualClass.create(:superclass => 'Post', :name => 'Super', :create_group_id => groups_id(:public))
    assert !vclass.new_record?

    login(:anon)
    
    assert_equal %w{Post Super}, VirtualClass['Post'].sub_classes.map(&:name)
  end

  def test_post_classes_for_form_opt
    # add a sub class
    login(:lion)
    vclass = VirtualClass.create(:superclass => 'Post', :name => 'Super', :create_group_id => groups_id(:public))
    assert !vclass.new_record?

    login(:anon)

    classes_for_form = Node.classes_for_form(:class => 'Post')
    assert classes_for_form.include?(["Post", "Post"])
    assert classes_for_form.include?(["  Super", "Super"])
    classes_for_form.map!{|k,c| c}
    assert !classes_for_form.include?("Node")
    assert !classes_for_form.include?("Note")
    assert !classes_for_form.include?("Letter")
    assert !classes_for_form.include?("Page")
    assert !classes_for_form.include?("Reference")
  end

  def test_post_classes_for_form_opt
    # add a sub class
    login(:lion)
    vclass = VirtualClass.create(:superclass => 'Post', :name => 'Super', :create_group_id => groups_id(:public))
    assert !vclass.new_record?

    login(:anon)

    classes_for_form = Node.classes_for_form(:class => 'Post', :without=>'Super')

    assert classes_for_form.include?(["Post", "Post"])
    classes_for_form.map!{|k,c| c}
    assert !classes_for_form.include?("Node")
    assert !classes_for_form.include?("Note")
    assert !classes_for_form.include?("Letter")
    assert !classes_for_form.include?("Page")
    assert !classes_for_form.include?("Reference")
    assert !classes_for_form.include?("Super")
  end

  def test_node_classes_for_form_except
    login(:anon)
    # preload models
    [Project, Skin, Note, Image, Template]

    classes_for_form = Node.classes_for_form(:without => 'Letter')
    assert classes_for_form.include?(["Node", "Node"])
    assert classes_for_form.include?(["  Page", "Page"])
    assert classes_for_form.include?(["  Note", "Note"])
    assert classes_for_form.include?(["  Reference", "Reference"])
    classes_for_form.map!{|k,c| c}
    assert !classes_for_form.include?("Letter")

    classes_for_form = Node.classes_for_form(:without => 'Letter,Reference,Truc')
    assert classes_for_form.include?(["Node", "Node"])
    assert classes_for_form.include?(["  Page", "Page"])
    assert classes_for_form.include?(["  Note", "Note"])
    classes_for_form.map!{|k,c| c}
    assert !classes_for_form.include?("Letter")
    assert !classes_for_form.include?("Reference")
  end

  def test_node_classes_read_group
    login(:anon)
    classes_for_form = Node.classes_for_form
    assert !classes_for_form.include?(["    TestNode", "TestNode"])
    login(:lion)
    classes_for_form = Node.classes_for_form
    assert classes_for_form.include?(["    TestNode", "TestNode"])
  end

  def test_vkind_of
    letter = secure!(Node) { nodes(:letter) }
    assert letter.vkind_of?('Letter')
    assert letter.vkind_of?('Note')
    assert letter.kpath_match?('NN')
    assert letter.kpath_match?('NNL')
  end

  def test_create_letter
    login(:ant)
    assert node = secure!(Node) { Node.create_node(:title => 'my letter', :paper => 'Manila', :class => 'Letter', :parent_id => nodes_zip(:cleanWater)) }
    assert_equal "NNL", node.kpath
    assert_kind_of Note, node
    assert_kind_of VirtualClass, node.virtual_class
    assert_equal roles_id(:Letter), node.vclass_id
    assert_equal 'Letter', node.klass
    assert_equal 'Manila', node.paper
    assert node.vkind_of?('Letter')
    assert_equal "NNL", node.virtual_class[:kpath]
    assert_equal "NNL", node[:kpath]
  end


  def test_relation
    login(:ant)
    node = secure!(Node) { nodes(:zena) }
    #assert letters = node.find(:all,'letters')
    query = Node.build_query(:all, 'letters', :node_name => 'node')
    assert letters = Node.do_find(:all, eval(query.to_s))
    assert_equal 1, letters.size
    assert letters[0].vkind_of?('Letter')
    assert_kind_of Note, letters[0]
  end

  def test_superclass
    assert_equal VirtualClass['Note'], roles(:Post).superclass
    assert_equal VirtualClass['Note'], roles(:Letter).superclass
    assert_equal VirtualClass['Page'], roles(:TestNode).superclass
  end

  def test_new_conflict_virtual_kpath
    # add a sub class
    login(:lion)
    vclass = VirtualClass.create(:superclass => 'Note', :name => 'Pop', :create_group_id =>  groups_id(:public))
    assert !vclass.new_record?
    assert_not_equal Node.get_class('Post').kpath, vclass.kpath
    assert_equal 'NNO', vclass.kpath
  end

  def test_new_conflict_kpath
    # add a sub class
    login(:lion)
    vclass = VirtualClass.create(:superclass => 'Page', :name => 'Super', :create_group_id =>  groups_id(:public))
    assert !vclass.new_record?
    assert_not_equal Section.kpath, vclass.kpath
    assert_equal 'NPU', vclass.kpath
    # New class without any free key
    vclass = VirtualClass.create(:superclass => 'Page', :name => 'U', :create_group_id =>  groups_id(:public))
    assert !vclass.new_record?
    assert_equal 'NPA', vclass.kpath
  end

  context 'Updating a VirtualClass' do
    setup do
      login(:lion)
    end

    subject do
      roles(:Post)
    end

    should 'update kpaths in nodes' do
      # kpath NNP => NO
      assert subject.update_attributes(:superclass => 'Page')
      assert_equal 'NPO', subject.kpath
      n = nodes(:opening)
      assert_equal 'NPO', n.kpath
    end

    should 'update kpaths in relations' do
      # kpath NNP => NO
      assert subject.update_attributes(:name => 'Frost')
      assert_equal 'NNF', subject.kpath
      rel = relations(:post_has_blogs)
      assert_equal 'NNF', rel.source_kpath
    end

    context 'with a related template' do
      setup do
        @template = secure(Template) { Template.create(:parent_id => nodes_id(:default), :title => 'Post-foobar.zafu') }
        assert !@template.new_record?
      end

      should 'update kpaths in templates' do
        # kpath NNP => NO
        assert subject.update_attributes(:superclass => 'Page')
        assert_equal 'NPO', subject.kpath
        t = secure(Template) { Template.find(@template) }
        assert_equal 'NPO', t.tkpath
        idx = IdxTemplate.first(:conditions => {:node_id => t.id})
        assert_equal 'NPO', idx.tkpath
      end

      should 'rename templates' do
        # kpath NNP => NO
        assert subject.update_attributes(:name => 'Fast')
        assert_equal 'NNF', subject.kpath
        t = secure(Template) { Template.find(@template) }
        assert_equal 'NNF', t.tkpath
        assert_equal 'Fast-foobar', t.title
        idx = IdxTemplate.first(:conditions => {:node_id => t.id})
        assert_equal 'NNF', idx.tkpath
      end
    end # with a related template

    context 'with sub vclasses' do
      setup do
        @sub = secure(VirtualClass) { VirtualClass.create(:superclass => subject, :name => 'Dog') }
        assert !@sub.new_record?
      end

      should 'update kpaths in sub vclass' do
        # kpath NNP => NO
        assert subject.update_attributes(:superclass => 'Page')
        assert_equal 'NPO', subject.kpath
        sub = VirtualClass.find(@sub)
        assert_equal 'NPOD', sub.kpath
      end
    end # with a related template


    context 'with linked role' do
      setup do
        @role = ::Role.create('name' => 'Foobar', 'superclass' => 'Post')
        assert !@role.new_record?
        assert_equal 'NNP', @role.kpath
      end

      should 'update linked role kpath' do
        # kpath NNP => NO
        assert subject.update_attributes(:superclass => 'Page')
        assert_equal 'NPO', subject.kpath
        role = ::Role.find(@role)
        assert_equal 'NPO', role.kpath
      end
    end # with linked role

  end # Updating a VirtualClass

  def test_update_name
    # add a sub class
    login(:lion)
    vclass = roles(:Post)
    assert_equal "NNP", vclass.kpath
    assert vclass.update_attributes(:name => 'Past')
    assert_equal "NNP", vclass.kpath
  end

  def test_update_superclass
    # add a sub class
    login(:lion)
    vclass = roles(:Post)
    assert_equal VirtualClass['Note'], vclass.superclass
    assert vclass.update_attributes(:superclass => 'Project')
    assert_equal VirtualClass['Project'], vclass.superclass
    assert_equal "NPPP", vclass.kpath
  end

  def test_auto_create_discussion
    assert !roles(:Letter).auto_create_discussion
    assert roles(:Post).auto_create_discussion
  end

  context 'Loading a virtual class' do
    context 'with a kpath' do
      subject do
        VirtualClass['Post']
      end

      should 'return a virtual class' do
        assert_kind_of VirtualClass, subject
        assert_equal 'Post', subject.name
      end

      should 'cache found virtual class' do
        assert_equal VirtualClass['Post'].object_id, subject.object_id
      end

      should 'return a loaded virtual class' do
        assert_equal POST_PROPERTIES, subject.column_names.sort
      end

      context 'related to a real class' do
        subject do
          VirtualClass.find_by_kpath('NN')
        end

        should 'return a virtual class' do
          assert_kind_of VirtualClass, subject
          assert_equal 'Note', subject.name
        end

        should 'return a loaded virtual class' do
          assert_equal NOTE_PROPERTIES, subject.column_names.sort
        end
      end # related to a real class

    end # with a kpath

    context 'with an id' do
      subject do
        VirtualClass.find_by_id roles_id(:Post)
      end

      should 'return a virtual class' do
        assert_kind_of VirtualClass, subject
        assert_equal 'Post', subject.name
      end

      should 'cache found virtual class' do
        assert_equal VirtualClass.find_by_id(roles_id(:Post)), subject
        assert_equal VirtualClass['Post'].object_id, subject.object_id
      end

      should 'return a loaded virtual class' do
        assert_equal POST_PROPERTIES, subject.column_names.sort
      end
    end # with an id


    context 'with a name' do
      subject do
        VirtualClass.find_by_name 'Post'
      end

      should 'return a virtual class' do
        assert_kind_of VirtualClass, subject
        assert_equal 'Post', subject.name
      end

      should 'cache found virtual class' do
        assert_equal VirtualClass.find_by_id(roles_id(:Post)).object_id, subject.object_id
        assert_equal VirtualClass['Post'].object_id, subject.object_id
      end

      should 'return a loaded virtual class' do
        assert_equal POST_PROPERTIES, subject.column_names.sort
      end

      context 'related to a real class' do
        subject do
          VirtualClass.find_by_name('Note')
        end

        should 'return a virtual class' do
          assert_kind_of VirtualClass, subject
          assert_equal 'Note', subject.name
        end

        should 'return a loaded virtual class' do
          assert_equal NOTE_PROPERTIES, subject.column_names.sort
        end
      end # related to a real class
    end # with a name

    context 'from a node instance' do
      subject do
        nodes(:proposition)
      end

      should 'load from cache' do
        assert_equal VirtualClass['Post'].object_id, subject.virtual_class.object_id
      end

      context 'that is not a virtual class instance' do
        subject do
          nodes(:projects)
        end

        should 'load from cache' do
          assert_equal VirtualClass['Page'].object_id, subject.virtual_class.object_id
        end
      end # that is not a virtual class instance

    end # from a node instance
  end # Loading a virtual class
  
  context 'With a virtual class linked to a real class' do
    setup do
      login(:lion)
      vclass = secure(VirtualClass) { VirtualClass.create(:superclass => 'Document', :name => 'Image')}
    end

    should 'description' do
      
    end
  end
  

  def self.should_clear_cache

    should 'update roles_updated_at date' do
      subject
      date = current_site.roles_updated_at
      assert_equal date.to_i, Site.find(current_site.id).roles_updated_at.to_i # to_i because of the precision in db
      assert_kind_of Time, date
      assert @before < current_site.roles_updated_at
    end

    should 'empty process cache' do
      # in same process
      subject
      cache = VirtualClass.caches_by_site[current_site.id]
      assert cache.instance_variable_get(:@cache_by_id).empty?
      assert cache.instance_variable_get(:@cache_by_kpath).empty?
      assert cache.instance_variable_get(:@cache_by_name).empty?
    end

    should 'mark cache' do
      subject
      # This is needed for other processes
      assert @cache.stale?
    end
  end

  def setup_cache_test
    login(:lion)
    Site.connection.execute 'UPDATE sites SET roles_updated_at = NULL'
    # preload in cache
    VirtualClass['Post'].column_names
    @before = Time.now.utc
    @cache  = VirtualClass.caches_by_site[current_site.id]
  end

  context 'Creating a Role' do
    setup do
      setup_cache_test
    end

    subject do
      role = VirtualClass.create(:name => 'Flop', :superclass => 'Project', :create_group_id => groups_id(:public))
      role
    end

    should_clear_cache

    should 'create new role' do
      assert_difference('VirtualClass.count', 1) do
        subject
      end
    end

    should 'load new role from cache' do
      subject
      assert_kind_of VirtualClass, VirtualClass.find_by_name('Flop')
    end

    should 'set real_class' do
      assert_equal Project, subject.real_class
    end
  end # Creating a Role

  context 'Creating a Column' do
    setup do
      setup_cache_test
    end

    subject do
      column = Column.create(:role_id => roles_id(:Original), :ptype => 'string', :name => 'foo')
      err column
      assert !column.new_record?
    end

    should_clear_cache

    should 'load new role from cache' do
      subject
      # no more linked to assigned
      assert_equal %w{assigned cached_role_ids date foo info origin settings summary text title tz weight}, VirtualClass['Post'].column_names.sort
    end

  end # Creating a Column

  context 'Updating a Role' do
    setup do
      setup_cache_test
    end

    subject do
      assert roles(:Original).update_attributes(:superclass => 'Page')
    end

    should_clear_cache

    should 'load new role from cache' do
      subject
      # no more linked to Original
      assert_equal %w{assigned cached_role_ids date info summary text title}, VirtualClass['Post'].column_names.sort
    end

  end # Updating a Role

  context 'Updating a Column' do
    setup do
      setup_cache_test
    end

    subject do
      assert columns(:Original_tz).update_attributes(:name => 'toz')
    end

    should_clear_cache

    should 'load new role from cache' do
      subject
      # change name
      assert_equal POST_PROPERTIES.map{|p| p == 'tz' ? 'toz' : p}, VirtualClass['Post'].column_names.sort
    end

  end # Updating a Column

  context 'Deleting a Role' do
    setup do
      setup_cache_test
    end

    subject do
      assert roles(:Original).destroy
    end

    should_clear_cache

    should 'load new role from cache' do
      subject
      # no more linked to Original
      assert_equal %w{assigned cached_role_ids date info summary text title}, VirtualClass['Post'].column_names.sort
    end

  end # Deleting a Role

  context 'Deleting a Column' do
    setup do
      setup_cache_test
    end

    subject do
      assert columns(:Original_tz).destroy
    end

    should_clear_cache

    should 'load new role from cache' do
      subject
      # no more linked to assigned
      assert_equal %w{assigned cached_role_ids date info origin settings summary text title weight}, VirtualClass['Post'].column_names.sort
    end

  end # Deleting a Column

  context 'Finding all classes' do
    subject do
      VirtualClass.all_classes
    end

    context 'without base or filter' do
      should 'load all classes' do
        assert_equal %w{N ND NDI NDT NDTT NN NNL NNP NP NPE NPP NPPB NPS NPSS NPT NR NRC}, subject.map(&:kpath).reject{|k| k =~ /\ANU|\ANDD/}.sort
      end
    end # without base or filter

    context 'with a base' do
      subject do
        VirtualClass.all_classes('ND')
      end

      should 'load sub classes and self' do
        VirtualClass.expire_cache!
        assert_equal %w{ND NDI NDT NDTT}, subject.map(&:kpath).sort.reject{|k| k == 'NDD'} # test leakage
      end
    end # with a base

    context 'with a filter' do
      subject do
        VirtualClass.all_classes('N', 'Document')
      end

      should 'description' do
        assert_equal %w{N NN NNL NNP NP NPE NPP NPPB NPS NPSS NPT NR NRC}, subject.map(&:kpath).reject{|k| k =~ /\ANU/}.sort
      end
    end # with a filter

  end # Finding all classes

  context 'A Document vclass' do
    context 'on new_instance' do
      subject do
        VirtualClass['Document'].new_instance(
            :parent_id => nodes_id(:cleanWater),
            :file      => uploaded_jpg('bird.jpg')
        )
      end

      should 'select class from content type' do
        assert_kind_of Image, subject
      end
    end # on new_instance
  end # A Document vclass

  context 'A vclass' do
    context 'of a real class' do
      subject do
        VirtualClass['Page']
      end

      should 'return true on real_class?' do
        assert subject.real_class?
      end

      should 'return super vclass' do
        assert_equal VirtualClass['Node'], subject.superclass
      end

      should 'return safe column types' do
        assert_equal %w{assigned origin settings summary text title tz weight}, subject.safe_column_types.keys.sort
      end

      should 'return nil on unsafe method type' do
        assert_nil subject.safe_method_type(['cached_role_ids'])
      end

      should 'return type on safe method type' do
        assert_equal Hash[:class => String, :nil => true, :method => "prop['title']"], subject.safe_method_type(['title'])
      end

      should 'return list of roles' do
        assert_equal %w{Node Original Task}, subject.sorted_roles.map(&:name)
      end
      
      should 'return real_class name on get_real_class' do
        assert_equal 'Page', subject.send(:get_real_class, subject)
      end
      
      should 'respond to monolingual' do
        assert_nothing_raised do
          assert_nil subject.monolingual
        end
      end

      context 'that is a Node' do
        subject do
          VirtualClass['Node']
        end

        should 'return Node on super vclass' do
          assert_equal Node, subject.superclass
        end

        should 'return safe columns' do
          assert_equal %w{summary text title assigned origin settings tz weight}, subject.safe_columns.map(&:name)
        end

        should 'return defined safe columns' do
          assert_equal %w{summary text title}, subject.defined_safe_columns.map(&:name)
        end

        should 'return safe column types' do
          assert_equal %w{assigned origin settings summary text title tz weight}, subject.safe_column_types.keys.sort
        end

        should 'not include unsafe properties in safe column types' do
          unsafe_prop = 'cached_role_ids'
          assert subject.columns[unsafe_prop]
          assert !subject.safe_column_types[unsafe_prop]
        end

        should 'return list of roles' do
          assert_equal %w{Node Original Task}, subject.sorted_roles.map(&:name)
        end
      end
      
      context 'linked to a real class' do
        subject do
          VirtualClass['Note']
        end

        should 'have an id' do
          assert subject.id
        end

        should 'define superclass' do
          assert_equal VirtualClass['Node'], subject.superclass
        end

        should 'be the superclass of descendants' do
          assert_equal subject, VirtualClass['Post'].superclass
        end

        should 'load all properties' do
          assert_equal %w{assigned cached_role_ids info origin settings summary text title tz weight}, subject.column_names.sort
        end

        should 'return list of roles' do
          assert_equal %w{Node Original Task Note}, subject.sorted_roles.map(&:name)
        end
        
        should 'define safe columns' do
          assert_equal %w{info}, subject.defined_safe_columns.map(&:name)
        end
      end

    end # of a real class


    context 'of a virtual class' do
      subject do
        VirtualClass['Post']
      end

      should 'return false on real_class?' do
        assert !subject.real_class?
      end

      should 'return safe columns' do
        assert_equal %w{summary text title assigned origin settings tz weight info date}, subject.safe_columns.map(&:name)
      end

      should 'return defined safe columns' do
        assert_equal %w{date}, subject.defined_safe_columns.map(&:name)
      end

      should 'return safe column types' do
        assert_equal %w{assigned date info origin settings summary text title tz weight}, subject.safe_column_types.keys.sort
      end

      should 'return type on safe method type' do
        assert_equal Hash[:class => String, :nil => true, :method => "prop['title']"], subject.safe_method_type(['title'])
        assert_equal Hash[:class => Time, :nil => true, :method => "prop['date']"], subject.safe_method_type(['date'])
      end

      should 'return type of ruby method on safe method type' do
        assert_equal Hash[:class => Time, :nil => true, :method => "created_at"], subject.safe_method_type(['created_at'])
      end

      should 'return list of roles' do
        assert_equal %w{Node Original Task Note Post}, subject.sorted_roles.map(&:name)
      end
    end # of a virtual class


    context 'on all_relations' do
      subject do
        VirtualClass['Letter'].all_relations
      end

      should 'return a list of relation proxies' do
        assert_kind_of RelationProxy, subject.first
      end

      should 'return a list of relation names when mapped with other_role' do
        assert subject.map(&:other_role).include?('icon')
      end
    end # on relations


    context 'on filtered_relations' do
      subject do
        VirtualClass['Letter'].filtered_relations('doc')
      end

      should 'filter relation proxies' do
        assert_kind_of RelationProxy, subject.first
      end

      should 'return a list of relation names on other_role' do
        assert_equal %w{reference reference_for set_tag}, subject.map(&:other_role).sort
      end
    end # on relations

    context 'on new_instance' do
      subject do
        VirtualClass['Letter'].new_instance(
          :parent_id => nodes_id(:cleanWater),
          :title     => 'lambda'
        )
      end

      should 'use real_class' do
        assert_kind_of Note, subject
      end

      should 'set virtual class' do
        assert_equal VirtualClass['Letter'].object_id, subject.vclass.object_id
      end
    end # on new_instance
  end # A note vclass

  context 'A virtual class' do
    subject do
      VirtualClass['Post']
    end

    should 'respond to less or equal then' do
      assert subject <= Note
      assert subject <= Node
      assert subject <= VirtualClass['Note']
      assert !(subject <= Project)
    end

    should 'respond to less then' do
      assert subject < Note
      assert subject < Node
      assert subject < VirtualClass['Note']
      assert !(subject < Project)
      assert !(subject < VirtualClass['Post'])
    end

    should 'consider role methods as safe' do
      assert_equal Hash[:class=>String, :method=>"prop['assigned']", :nil=>true], subject.safe_method_type(['assigned'])
    end
    
    # with content_type
    #
  end # A virtual class
  
  context 'Creating a virtual class' do
    context 'with an admin visitor' do
      setup do
        login(:lion)
      end
      
      context 'with content_type' do
        subject do
          {
            :superclass      => 'Document',
            :name            => 'HtmlDoc',
            :create_group_id => groups_id(:public), 
            :content_type    => 'text/html',
          }
        end

        should 'save and create regexp' do
          v = secure(VirtualClass) { VirtualClass.new(subject) }
          assert v.save
          assert_equal %r{^text/html$}, v.content_type_re
        end
        
        should 'add an error on bad content_type' do
          v = secure(VirtualClass) { VirtualClass.new(subject.merge(:content_type => '(')) }
          assert !v.save
          assert_equal 'invalid characters', v.errors[:content_type]
        end
        
      end
      
      context 'linked to a real class' do
        subject do
          v = secure(VirtualClass) do
            VirtualClass.new({
              :superclass      => 'Document',
              :name            => 'Page',
              :create_group_id => groups_id(:public),
            })
          end
          v.save
          v
        end

        should 'save' do
          assert !subject.new_record?
        end
        
        should 'rewrite superclass' do
          subject
          assert_equal VirtualClass['Node'], subject.superclass
        end
        
        should 'properly set real_class' do
          assert_equal Page, subject.real_class
        end
        
        should 'echo kpath' do
          assert_equal Page.kpath, subject.kpath
        end
      end
      

      context 'linked to Node class' do
        subject do
          v = secure(VirtualClass) do
            VirtualClass.new({
              :name            => 'Node',
              :create_group_id => groups_id(:public),
            })
          end
          v.save
          v
        end

        should 'save' do
          err subject
          assert !subject.new_record?
        end

        should 'rewrite superclass' do
          assert_equal Node, subject.superclass
        end

        should 'properly set real_class' do
          assert_equal Node, subject.real_class
        end

        should 'echo kpath' do
          assert_equal Node.kpath, subject.kpath
        end
      end
    end
  end
  
  context 'A Virtual class' do
    context 'subclass of Document with content_type' do
      setup do
        login(:lion)
      end
      
      context 'with content_type' do
        subject do
          secure(VirtualClass) {
            VirtualClass.create(
              :superclass      => 'TextDocument',
              :name            => 'HtmlDoc',
              :create_group_id => groups_id(:public), 
              :content_type    => 'text/html'
            )}
        end

        should 'be used to create matching content_type documents' do
          klass = subject
          n = secure!(Document) { Document.create(
                :parent_id    => nodes_id(:cleanWater),
                :content_type => 'text/html',
                :file         => uploaded_text('some.txt'))
          }
              
          assert !n.new_record?
          assert_equal subject.name, n.klass
        end
      end
    end
  end
  
  context 'A visitor with write access' do
    setup do
      login(:tiger)
    end

    context 'on a node' do
      context 'from a class with roles' do
        subject do
          secure(Node) { nodes(:letter) }
        end

        should 'use method missing to assign properties' do
          assert_nothing_raised do
            subject.assigned = 'flat Eric'
          end
        end

        should 'use property filter on set attributes' do
          assert_nothing_raised do
            subject.attributes = {'assigned' => 'flat Eric'}
          end
        end

        should 'accept properties' do
          subject.properties = {'assigned' => 'flat Eric'}
          assert subject.save
          assert_equal 'flat Eric', subject.assigned
        end

        should 'use property filter on update_attributes' do
          assert_nothing_raised do
            assert subject.update_attributes('assigned' => 'flat Eric', 'origin' => '2D')
          end
        end

        should 'accept properties in update_attributes' do
          assert_nothing_raised do
            assert subject.update_attributes('properties' => {'assigned' => 'flat Eric'})
            assert_equal 'flat Eric', subject.assigned
          end
        end

        should 'consider role methods as safe' do
          assert_equal Hash[:class=>String, :method=>"prop['paper']", :nil=>true], subject.safe_method_type(['paper'])
        end

        should 'not consider VirtualClass own methods as safe' do
          assert_nil subject.safe_method_type(['name'])
        end

        should 'not allow arbitrary attributes' do
          assert !subject.update_attributes('assigned' => 'flat Eric', 'bad' => 'property')
        end

        should 'not raise on bad attributes' do
          assert_nothing_raised do
            subject.attributes = {'elements' => 'Statistical Learning'}
          end
        end

        should 'add an error on first bad attributes' do
          subject.attributes = {'elements' => 'Statistical Learning'}
          assert !subject.save
          assert_equal 'property not declared', subject.errors[:elements]
        end

        should 'not allow property bypassing' do
          assert !subject.update_attributes('properties' => {'bad' => 'property'})
          assert_equal 'property not declared', subject.errors[:bad]
        end

      end # from a class with roles
    end # on a node
  end # A visitor with write access


  context 'An admin' do
    setup do
      login(:lion)
    end

    context 'exporting a virtual class' do
      setup do
        login(:lion)
      end

      subject do
        VirtualClass['Post'].export
      end

      should 'export attributes' do
        assert_equal('VirtualClass', subject['type'])
      end

      should 'export columns' do
        assert_equal({
            'date' => {'index' => '.idx_datetime1', 'ptype' => 'datetime'},
        }, subject['columns'])
      end

      should 'export relations' do
        assert_equal({
          'blogs' => {'target_name'=>'Project', 'source_role'=>'added_note'}
        }, subject['relations'])
      end

      should 'export sub classes' do
        assert_equal(%w{Contact}, VirtualClass['Reference'].export.keys.select{|k| k=~/\A[A-Z]/})
      end
    end # exporting a virtual class

    context 'exporting a real class' do
      subject do
        VirtualClass['Page'].export
      end

      should 'export type as Class' do
        assert_equal('Class', subject['type'])
      end

      should 'export sub classes' do
        assert_equal(%w{TestNode Project Section Tag}, subject.keys.select{|k| k=~/\A[A-Z]/})
        assert_equal('VirtualClass', subject['TestNode']['type'])
        assert_equal('Class', subject['Project']['type'])
      end

      context 'with relations' do
        subject do
          VirtualClass['Project'].export
        end

        should 'export relations' do
          assert_equal(%w{collaborators home hot}, subject['relations'].keys)
        end
      end # with relations


      context 'with linked roles' do
        setup do
          secure(::Role) { ::Role.create('name' => 'Foo', 'superclass' => 'Page')}
        end

        should 'export linked roles' do
          assert(subject.keys.include?('Foo'))
          assert_equal('Role', subject['Foo']['type'])
        end
      end # with linked roles

    end # exporting a real class

    context 'importing definitions' do
      subject do
        {'Note' => {
          'type' => 'Class',
          'Bar' => {
            'type' => 'Role',
          },
          'Baz' => {
            'type' => 'VirtualClass',
            'Plop' => {
              'type' => 'VirtualClass',
            },
          },
        }}
      end

      should 'create roles and VirtualClasses' do
        assert_difference('Role.count', 3) do
          assert_difference('VirtualClass.count', 2) do
            VirtualClass.import(subject)
          end
        end
      end

      context 'with relations' do
        subject do
          s = Zafu::OrderedHash.new
          s['Note'] = Zafu::OrderedHash.new
          # created first with relations to next class
          s['Note']['Foo'] = {
            'type' => 'VirtualClass',
            'relations' => {
              'babar' => {
                'target_name'   => 'Post',
                'target_unique' => true,
                'source_role'   => 'fool',
                'rel_group'     => 'foo.bar',
              },
            },
          }

          s['Note']['Bar'] = {
            'type' => 'VirtualClass',
          }
          s
        end

        should 'create or update relations after vclass creation' do
          assert_difference('Relation.count', 1) do
            assert_difference('Role.count', 2) do
              VirtualClass.import(subject)
            end
          end
          assert foo = VirtualClass['Foo']
          assert bar = VirtualClass['Bar']
          rel = Relation.first(
            :conditions => ['source_kpath = ? AND target_role = ?', 'NNF', 'babar'])
          assert_equal 'NNP',   rel.target_kpath
          assert_equal 'fools', rel.source_role
          assert_equal 'babar', rel.target_role
          assert_equal 'foo.bar', rel.rel_group
        end
      end # with relations

    end
  end # An admin

end
