module Zena
  module Use
    module Ajax
      module ViewMethods
        include RubyLess
        safe_method :ajax? => {:class => Boolean, :method => 'params[:s]'}

        # Return the DOM id for a node. We had to name this method 'ndom_id' because we want
        # to avoid the clash with Rails' dom_id method.
        def ndom_id(node = @node, append_form = true)
          if node.kind_of?(Node) && !node.new_record?
            if params[:action] == 'create' && !params[:udom_id] && !params[:s]
              # !params[:s] is to not use this when executing Zena.post
              
              # We cannot filter with params[:zadd] because this breaks when editing in lists.
              return "#{params[:dom_id]}_#{node.zip}"
            end
          elsif append_form && node.kind_of?(Node) && params[:zadd] 
            return "#{params[:dom_id]}_#{node.zip.to_i}"
          end

          @dom_id || params[:udom_id] || params[:dom_id]
        end

        # RJS to update a page after create/update/destroy
        def update_page_content(page, obj)
          unless params[:dom_id]
            # simply reply with failure or success
            if !obj.errors.empty?
              page << "alert(#{obj.errors.first.join(': ')});"
              page << "return false;" # How to avoid 'onSuccess' ?
            elsif params[:udom_id] == '_page'
              # reload page
              page << "document.location.href = document.location.href;"
            else
              # ?
            end
            return
          end

          if params[:t_id] && obj.errors.empty?
            obj = secure(Node) { Node.find_by_zip(params[:t_id])}
            @node = obj
          end

          base_class = obj.kind_of?(Node) ? Node : obj.class

          if obj.new_record?
            # A. could not create object: show form with errors
            page.replace ndom_id, :file => template_path_from_template_url('_form')
          elsif @errors || !obj.errors.empty?
            # B. could not update/delete: show errors
            form_file = template_path_from_template_url('_form')
            if File.exist?(form_file)
              page.replace ndom_id, :file => form_file
            else
              page.insert_html :top, params[:dom_id], :inline => render_errors
            end
          elsif params[:udom_id]
            if params[:udom_id] == '_page'
              # reload page
              page << "document.location.href = document.location.href;"
            else
              # C. update another part of the page
              if node_id = params[:u_id]
                if node_id.to_i != obj.zip
                  if base_class == Node
                    instance_variable_set("@#{base_class.to_s.underscore}", secure(base_class) { base_class.find_by_zip(node_id) })
                  else
                    instance_variable_set("@#{base_class.to_s.underscore}", secure(base_class) { base_class.find_by_id(node_id) })
                  end
                end
              end
              page.replace params[:udom_id], :file => template_path_from_template_url('', params[:u_url] || params[:t_url])
              if params[:upd_both]
                @dom_id = params[:dom_id]
                page.replace params[:dom_id], :file => template_path_from_template_url
              end
              if params[:done] && params[:zadd]
                page.toggle "#{params[:dom_id]}_0", "#{params[:dom_id]}_add"
                page << params[:done]
              elsif params[:done]
                page << params[:done]
              end
            end
          else
            # D. normal update
            #if params[:dom_id] == '_page'
            #  # reload page
            #  page << "document.location.href = document.location.href;"
            #

            case params[:action]
            when 'edit'
              page.replace params[:dom_id], :file => template_path_from_template_url
              page << "$('#{params[:dom_id]}_form_t').focusFirstElement();"
            when 'create'
              if params[:zadd]
                # ADD WITH FORM...
                pos = params[:position]  || :before
                ref = params[:reference] || "#{params[:dom_id]}_add"
                page.insert_html pos.to_sym, ref, :file => template_path_from_template_url
                if obj.kind_of?(Node)
                  @node = obj.parent.new_child(:class => obj.class)
                else
                  instance_variable_set("@#{base_class.to_s.underscore}", obj.clone)
                end
                page.replace ndom_id, :file => template_path_from_template_url('_form')
                if params[:done]
                  page << params[:done]
                elsif params[:zadd]
                  page.toggle "#{params[:dom_id]}_0", "#{params[:dom_id]}_add"
                end
              else
                # Zena.post operation
                page.replace ndom_id, :file => template_path_from_template_url
                page << params[:done] if params[:done]
              end
            when 'update'
              page.replace ndom_id, :file => template_path_from_template_url
              page << params[:done] if params[:done]
            when 'destroy'
              page << %Q{
                new Effect.Highlight('#{ndom_id}', {
                  duration: 0.3,
                  afterFinish: function() {
                    new Effect.Fade('#{ndom_id}', {
                      duration: 0.5,
                      afterFinish: function() {
                      $('#{ndom_id}').remove();
                      }
                    });
                  }
                });
              }
            when 'drop'
              case params[:done]
              when 'remove'
                page.visual_effect :highlight, params[:drop], :duration => 0.3
                page.visual_effect :fade, params[:drop], :duration => 0.3
              end
              page.replace params[:dom_id], :file => template_path_from_template_url
            else
              if position = params[:insert]
                page.call 'Zena.insert_inner', params[:dom_id], position, render(:file => template_path_from_template_url)
              else
                page.replace params[:dom_id], :file => template_path_from_template_url
              end
            end
          end
          if params[:redir]
            page << "window.location.href = '#{params[:redir]}';"
          end
          if params[:reload]
            page << "Zena.reload(#{params[:reload].inspect});"
          end
          page << render_js(false)
        end

        # Used by zafu to set dom_id that need to be made draggable.
        def add_drag_id(dom_id, js_options = nil)
          @drag_ids ||= {}
          (@drag_ids[js_options] ||= []) << dom_id
        end

        # Used by zafu to transform a dom_id into a droppable element.
        def add_drop_id(dom_id, options)
          js_data << "Droppables.add('#{dom_id}', {hoverclass:'#{options[:hover] || 'drop_hover'}', onDrop:function(element){
  new Ajax.Request('#{options[:url]}', {asynchronous:true, evalScripts:true, method:'put', parameters:'drop=' + encodeURIComponent(element.id)});
}});"
        end

        def add_toggle_id(dom_id, group_name, role, opts = {})
          arity = opts[:arity] || 'many'
          if js = opts[:js]
            js = ", js:function(e) { #{js} }"
          end
          
          @toggle_ids ||= {}
          unless list = @toggle_ids[group_name]
            list = @toggle_ids[group_name] = []

            if other = yield
              found = other.rel[role].other_zips
            else
              found = []
            end
            url = "/nodes/#{other.zip}"
            js_data << "#{group_name} = {list:#{found.inspect}, url:#{url.inspect}, role:#{role.inspect}, arity:#{arity.inspect}#{js}};"
          end
          list << dom_id
        end

        def filter_form(node, dom_id, loading, upd)
          if loading
            loading = "\n#{loading}($('#{upd}'));"
          else
            loading = ''
          end
          # Disable 'redir' parameter during preview or filter.
          js_data << %Q{new Form.Observer('#{dom_id}', 0.3, function(element, value) {#{loading}
            var data = Form.serialize('#{dom_id}').gsub(/&redir=/,'&no_redir=')
            new Ajax.Request('#{zafu_node_path(node)}', {asynchronous:true, evalScripts:true, method:'post', parameters:data})
          });}
        end
        
        # Load parameters in node before rendering.
        # SECURITY: There may be a security threat here if the node attributes are used for queries or relations.
        def preview_node(node)
          return nil if !node.kind_of?(Node)
          if attrs = params[:node]
            # Return a copy
            new_node = node.dup
            new_node.version = node.version.dup
            new_node.attributes = Node.transform_attributes(params[:node], node, true)
            return new_node
          else
            return node
          end
        end

        # Include draggable ids in bottom of page Javascript.
        def render_js(in_html = true)
          if @drag_ids
            @drag_ids.each do |js_options, list|
              if js_options.nil?
                js_data << %Q{#{list.inspect}.each(Zena.draggable);}
              else
                js_data << %Q{#{list.inspect}.each(function(item) { Zena.draggable(item, #{js_options})});}
              end
            end
          end

          if @toggle_ids
            @toggle_ids.each do |group_name, list|
              js_data << %Q{#{list.inspect}.each(function(item) { Zena.set_toggle(item, #{group_name})});}
            end
          end

          # Super is in Zena::Use::Rendering
          super
        end
      end # ViewMethods

      module ZafuMethods
        def self.included(base)
          # TODO: move process_toggle in 'before_wrap' callback so that 'node' is properly set.
          base.before_process :process_drag, :process_toggle
          base.before_wrap    :wrap_with_drag
        end

        def process_drag
          @drag_param = @params.delete(:draggable)
        end

        # Force an id on the current tag and record the DOM_ID to make the element draggable.
        def wrap_with_drag(text)
          # do not render drag in make_form
          return text unless @drag_param && !@context[:make_form]
          drag = @drag_param

          if @markup.params[:id] || (@markup.done && @method == 'link') # hack to rewrap link...
            # we do not mess with the original but use our own markup
            markup = @wrap_markup = Zafu::Markup.new('span')
          else
            markup = @markup
          end

          markup.tag ||= 'div'

          if node.instance_variable_get(:@dom_prefix).blank?
            # make sure we have a scope
            node.dom_prefix = dom_name
          end

          if erb_dom_id = markup.dyn_params[:id]
            # id set, get erb id
          else
            # We do not want to use the same id as the 'each' loop but we also want to
            # avoid changing the node context
            @drag_prefix ||= root.get_unique_name('drag', true).gsub(/[^\d\w\/]/,'_')
            erb_dom_id = node.dom_id(:dom_prefix => @drag_prefix)
            markup.set_id(erb_dom_id)
          end

          dom_id = erb_dom_id[/<%=\s*(.*?)\s*%>/,1]

          markup.append_param(:class, 'drag')

          drag = 'drag_handle' if drag == 'true'

          if drag == 'all'
            js_options = ['false']
          else
            unless @blocks.detect{|b| b.kind_of?(String) ? b =~ /class=.#{drag}/ : (b.params[:class] == drag || (b.markup && b.markup.params[:class] == drag))}
              handle = "<span class='#{drag}'>&nbsp;</span>"
            end
            js_options = [drag.inspect]
          end

          if revert = @params.delete(:revert)
            js_options << (%w{true false}.include?(revert) ? revert : revert.inspect)
          end

          markup.pre_wrap[:drag] = "#{handle}<% add_drag_id(#{dom_id}, #{js_options.join(', ').inspect}) %>"

          if @markup == markup
            text
          else
            markup.wrap(text)
          end
        end

        def r_preview_node
          expand_if("#{var} = preview_node(#{node})", node.move_to(var, node.klass))
        end
        
        # Display an input field to filter a remote block.
        def r_filter
          if upd = @params[:update]
            return unless block = find_target(upd)
          else
            return parser_error("missing 'block' in same parent") unless parent && block = parent.descendant('block')
            if block.name.blank?
              block.name ||= unique_name
            end
            upd = block.name
          end

          return parser_error("cannot use 's' as key (used by start_node)") if @params[:key] == 's'

          # Move up in case we are in a list.
          if self.node.list_context?
            base_node = self.node.up(Node)
          else
            base_node = self.node
          end
          
          # Do not alter current node, create our own
          with_context(:node => base_node.dup) do
            node.dom_prefix = dom_name
            dom_id = node.dom_id(:erb => false)
            
            # TODO: add 'encode_params' and x='"foobar"' to add any value in the request
            out %Q{<%= form_remote_tag(:url => zafu_node_path(#{node}), :method => :get, :html => {:id => \"#{dom_id}_f\"}) %>
            <div class='hidden'>
              <input type='hidden' name='t_url' value='#{template_url(upd)}'/>
              <input type='hidden' name='dom_id' value='#{upd}'/>
              <input type='hidden' name='s' value='<%= start_node_zip %>'/>
            </div><div class='wrapper'>
            }
            if @blocks == []
              out "<input type='text' name='#{@params[:key] || 'f'}' value='<%= params[#{(@params[:key] || 'f').to_sym.inspect}] %>'/>"
            else
              out expand_with(:in_filter => true)
            end
            out "</div></form>"
            loading = @params[:loading]
            loading = 'Zena.loading' if loading == 'true'
            if @params[:live] || @params[:update]
              out "<% filter_form(#{node}, \"#{dom_id}_f\", #{loading.inspect}, '#{upd}') %>"
            end  
          end
        end

        # Create a drop block.
        def r_drop
          if parent.method == 'each' && @method == parent.single_child_method
            # We reuse the 'each' block.
            target = parent
          else
            # Avoid altering parent node
            @context[:node] = node.dup

            node.dom_prefix = dom_name
            target = self
          end

          node = target.node
          markup = target.markup

          markup.tag ||= 'div'

          dom_id, dom_prefix = get_dom_id(target)

          markup.append_param(:class, 'drop') unless markup.params[:class] =~ /drop/

          if hover  = @params.delete(:hover)
            query_params = ", :hover => %{#{hover}}"
          else
            query_params = ""
          end

          if role = @params.delete(:set) || @params.delete(:add)
            @params["node[#{role}_id]"] = "'\#{id}'"
          end

          url_params = {}
          @params.each do |k,v|
            case k
            when :change, :done
              # Force string interpolation
              url_params[k] = "%{#{v}}"
            else
              url_params[k] = v
            end
          end

          query_params << ", :url => #{make_href(target, :action => 'drop', :query_params => url_params)}"
          markup.pre_wrap[:drop] = "<% add_drop_id(#{dom_id}#{query_params}) %>"
          r_block
        end

        # Create a link to toggle relation on/off
        def r_toggle
          return parser_error("missing 'set' or 'add' parameter") unless role = @params.delete(:set) || @params.delete(:add)
          return parser_error("missing 'for' parameter") unless finder = @params.delete(:for)

          finder = RubyLess.translate(self, finder)
          return parser_error("Invalid class 'for' parameter: #{finder.klass}") unless finder.klass <= Node

          node.dom_prefix = dom_name
          var = root.get_unique_name('tog')
          dom_id = node.dom_id(:erb => false)
          markup.set_id(node.dom_id)
          markup.append_param(:class, 'toggle')
          opts = {}
          if arity = @params.delete(:arity)
            opts[:arity] = arity
          end
          
          if js = @params.delete(:js)
            opts[:js] = js
          end
          
          out "<% add_toggle_id(\"#{dom_id}\", #{var.inspect}, #{RubyLess.translate_string(self, role)},#{opts.inspect}) { #{finder} } %>#{expand_with}"
        end

        def process_toggle
          return unless role = @params.delete(:toggle)

          unless finder = @params.delete(:for)
            out parser_error("missing 'for' parameter")
            return
          end

          finder = RubyLess.translate(self, finder)
          unless finder.klass <= Node
            out parser_error("Invalid class 'for' parameter: #{finder.klass}")
            return
          end

          node = pre_filter_node

          if dom_id = @markup.params[:id]
            # we do not mess with it
          else
            node.dom_prefix = dom_name
            markup.set_id(node.dom_id)
            dom_id = node.dom_id(:erb => false)
          end

          markup.tag ||= 'div'

          markup.append_param(:class, 'toggle')
          
          opts = []
          if arity = @params.delete(:arity)
            opts << ":arity => #{RubyLess.translate_string(self, arity)}"
          end
          
          if js = @params.delete(:js)
            opts << ":js => #{RubyLess.translate_string(self, js)}"
          end
          var = root.get_unique_name('tog')
          markup.pre_wrap[:toggle] = "<% add_toggle_id(\"#{dom_id}\", #{var.inspect}, #{RubyLess.translate_string(self, role)},{#{opts.join(', ')}}) { #{finder} } %>"
        end

        def r_unlink
          return '' if @context[:make_form]
          opts = {}

          if upd = @params[:update]
            if upd == '_page'
              target = nil
            elsif target = find_target(upd)
              # ok
            else
              return
            end
          elsif target = ancestor('block')
            # ok
          else
            target = self
          end

          opts[:update] = target

          if node.will_be?(Node)
            opts[:action] = 'unlink'
          elsif node.will_be?(Link)
            # ?
            opts[:url] = "/nodes/\#{#{node}.this_zip}/links/\#{#{node}.zip}"
          end

          opts[:default_text] = _('btn_tiny_del')
          @params[:class] ||= 'unlink'

          out "<% if #{node}.can_write? && #{node}.link_id %>#{wrap(make_link(opts))}<% end %>"

         #tag_to_remote
         #"<%= tag_to_remote({:url => node_path(#{node_id}) + \"#{opts[:method] != :put ? '/zafu' : ''}?#{action.join('&')}\", :method => #{opts[:method].inspect}}) %>"
         #  out "<a class='#{@params[:class] || 'unlink'}' href='/nodes/#{erb_node_id}/links/<%= #{node}.link_id %>?#{action}' onclick=\"new Ajax.Request('/nodes/#{erb_node_id}/links/<%= #{node}.link_id %>?#{action}', {asynchronous:true, evalScripts:true, method:'delete'}); return false;\">"
         #  if !@blocks.empty?
         #    inner = expand_with
         #  else
         #    inner = _('btn_tiny_del')
         #  end
         #  out "#{inner}</a><% else %>#{inner}<% end %>"
         #elsif node.will_be?(DataEntry)
         #  text = get_text_for_erb
         #  if text.blank?
         #    text = _('btn_tiny_del')
         #  end
         #  out "<%= link_to_remote(#{text.inspect}, {:url => \"/data_entries/\#{#{node}[:id]}?dom_id=#{dom_id}#{upd_url}\", :method => :delete}, :class=>#{(@params[:class] || 'unlink').inspect}) %>"
         #end
        end

        # Execute javascript after page/partial load.
        def r_js
          if @blocks.detect {|b| !b.kind_of?(String)}
            out "<% js_data << capture do %>"
            out expand_with
            out "<% end %>"
          else
            txt = @blocks.join('')
            out "<% js_data << #{txt.inspect} %>"
          end
        end
        
        # Only execute javascript on ajax.
        def r_ajs
          out "<% if params[:s] %>"
          r_js
          out "<% end %>"
        end

        def r_ajax?
          r_if(RubyLess.translate(self, 'ajax?'))
        end
        
        def r_reset_sort
          text = text_for_link(trans('reset_sort'))
          out "<a href='javascript:void()' onclick='Zena.resetSort(this)'>#{text}</a>"
        end
        
        protected

          def need_ajax?(each_block)
            return false unless each_block
            # Inline editable
            super ||
            # unlink
            each_block.descendant('unlink')
          end

          # Returns ruby for dom_id.
          #
          # FIXME: HACK
          # This dom_id detection code is crap but it fixes the drop in each bug.
          def get_dom_id(target)
            if @context[:saved_template]
              # Force ndom_id.
              dom_id = "ndom_id(#{node})"
            else

              if dom_id = target.markup.dyn_params[:id] || target.markup.params[:id]
                if dom_id =~ /^<%=\s+(.*?)\s+%>_0$/
                  # Rare case when we have a [drop] with [add]. (add element and then drop on it).
                  dom_id = $1
                elsif dom_id =~ /^<%=\s+(.*?)\s+%>$/
                  dom_id = $1
                else
                  dom_id = "%Q{#{dom_id}}"
                end

              elsif target.context
                # @context set, so node is available
                dom_id = "%Q{#{target.node.dom_id(
                  :list => target.method == 'each',
                  :erb => false
                )}}"

                target.markup.set_id(node.dom_id(
                  :list => target.method == 'each'
                ))
              else
                # Has not been rendered yet, does not have a dom_prefix set.
                dom_id = "%Q{#{target.dom_name}}"

                target.markup.set_id(node.dom_id(
                  :list => target.method == 'each'
                ))
              end
            end

            return [dom_id, target.context ? target.node.dom_prefix : target.dom_name]
          end
      end
    end # Ajax
  end # Use
end # Zena