
function branching_tree = trakem2_xml_to_sktree( s , tree_id_in )

% s = xml2struct(filename);

global node_count;

n_layers = numel(s.trakem2.t2_layer_set.t2_layer);
n_treelines = numel(s.trakem2.t2_layer_set.t2_treeline);

for i=1:n_layers
    
    % layer index 1:n_layers is "z" coord
    layers.layer(i).layer_id = str2double(s.trakem2.t2_layer_set.t2_layer{i}.Attributes.oid); %#ok<*AGROW>
    layers.z_of_layer_id(layers.layer(i).layer_id) = i;
    
    transform_string = s.trakem2.t2_layer_set.t2_layer{i}.t2_patch.Attributes.transform;
    a = sscanf(transform_string,'matrix(%f,%f,%f,%f,%f,%f)');
    layers.layer(i).affine_a = [a(1) a(2); a(3) a(4)];
    layers.layer(i).affine_b = [a(5); a(6)];
    
end

tree_count = 0;

for i = 1 : n_treelines

    transform_string = s.trakem2.t2_layer_set.t2_treeline{i}.Attributes.transform;
    a = sscanf(transform_string,'matrix(%f,%f,%f,%f,%f,%f)');
    treeline_affine.a = [a(1) a(2); a(3) a(4)];
    treeline_affine.b = [a(5); a(6)];

    node_count = 0;
    treeline_id = str2double(s.trakem2.t2_layer_set.t2_treeline{i}.Attributes.oid); 
    if ~( exist( 'treeline_id' , 'var' ) && ismember( treeline_id , tree_id_in ) )
        continue;
    end
    tree_count = tree_count + 1;
    branching_tree{tree_count}.tree_id = treeline_id;
    branching_tree{tree_count}.nodes = add_tree_nodes([], 0, s.trakem2.t2_layer_set.t2_treeline{i}, layers, treeline_affine);
    
end

end


function branching_tree_nodes = add_tree_nodes(branching_tree_nodes, prev_node_id, prev_node, layers, treeline_affine)

global node_count;

if ~isfield(prev_node, 't2_node')
    return;
end

if ~iscell(prev_node.t2_node)
    current_nodes{1} = prev_node.t2_node;
else
    current_nodes = prev_node.t2_node;
end


for i = 1:numel(current_nodes)

    node_count = node_count + 1;
    
    this_node = current_nodes{i};    
    this_node_id = node_count;
    this_tags = [];
    
    if isfield(this_node,'t2_tag')
        if ~iscell(this_node.t2_tag)
            this_tags{1} = this_node.t2_tag;
        else
            this_tags = this_node.t2_tag;
        end
            
        for j = 1 : numel(this_tags)
            branching_tree_nodes(this_node_id).tag(j).key = this_tags{j}.Attributes.key;
            branching_tree_nodes(this_node_id).tag(j).name = this_tags{j}.Attributes.name;
        end
    end

    if isfield(this_node,'Attributes')
        
        x_local = str2double(this_node.Attributes.x);
        y_local = str2double(this_node.Attributes.y);
        z = layers.z_of_layer_id(str2double(this_node.Attributes.lid));

        x = treeline_affine.a * [x_local; y_local] + treeline_affine.b; 
        branching_tree_nodes(this_node_id).voxel_x = x(1);
        branching_tree_nodes(this_node_id).voxel_y = x(2);
        branching_tree_nodes(this_node_id).voxel_z = z;
        
        branching_tree_nodes(this_node_id).physical_x = x(1) * 110;
        branching_tree_nodes(this_node_id).physical_y = x(2) * 110;
        branching_tree_nodes(this_node_id).physical_z = z * 85;        
        
    end    

    branching_tree_nodes(this_node_id).parent = prev_node_id;
    if ~(prev_node_id == 0)
        branching_tree_nodes(prev_node_id).children(i) = this_node_id;
    end

    branching_tree_nodes = add_tree_nodes(branching_tree_nodes, this_node_id, this_node, layers, treeline_affine);

end
    
end
