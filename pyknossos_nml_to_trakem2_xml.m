
function pyknossos_nml_to_trakem2_xml(nml_file_dir, template_xml_file_name, output_xml_file_name)

global lid layer_set_id layer_width layer_height id_count;

id_count = 1000;

s = xml2struct(template_xml_file_name); 

layer_set_id = str2double(s.trakem2.t2_layer_set.Attributes.oid); 
layer_width = str2double(s.trakem2.t2_layer_set.Attributes.layer_width); 
layer_height = str2double(s.trakem2.t2_layer_set.Attributes.layer_height); 

for i = 1 : numel(s.trakem2.t2_layer_set.t2_layer)
    z = str2double(s.trakem2.t2_layer_set.t2_layer{i}.Attributes.z) + 1;
    lid(z) = str2double(s.trakem2.t2_layer_set.t2_layer{i}.Attributes.oid); %#ok<*AGROW>
end

nml_file_list = dir(fullfile(nml_file_dir, '*.nml'));
trees = get_trees_from_nml(nml_file_list);

anything_string = compose_anything_string(trees);
treeline_string = compose_treeline_string(trees);

write_trakem2_xml_file_structure(output_xml_file_name, template_xml_file_name, anything_string, treeline_string);

end


function write_trakem2_xml_file_structure(output_xml_file_name, template_xml_file_name, anything_string, treeline_string)

% part1 (header. open <trakem2>\n<project ...>)
% INSERT: <anything > treeline list </anything>
% part2 (close </project>. open <t2_layer_set ...> open&close <t2_calibration .../>)
% INSERT: <t2_treeline ...> <t2_node> ... </t2_node> </t2_treeline> structure
% part3 (<t2_lyaer ...> <t2_patch ...> </t2_patch> </t2_layer> </t2_layer_set> </trakem2>

for i = 1 : 3
    file_name = sprintf('%s_part%d', template_xml_file_name, i);
    text_part{i} = fileread(file_name);
end

fo = fopen(output_xml_file_name, 'w');
fprintf(fo, '%s', text_part{1});
fprintf(fo, '%s', anything_string);
fprintf(fo, '%s', text_part{2});
fprintf(fo, '%s', treeline_string);
fprintf(fo, '%s', text_part{3});
fclose(fo);

end

function string = compose_anything_string(trees)

global id_count;

id_count = id_count + 1;
string = sprintf('\t\t<anything id="%d" expanded="true">\n', id_count);
for i = 1 : numel(trees)
    string = sprintf('%s\t\t\t<treeline id="%d" oid="%d"/>\n', string, trees{i}.id, trees{i}.oid);
end
string = sprintf('%s\t\t</anything>\n', string);

end

function string = compose_treeline_string(trees)

global layer_set_id layer_width layer_height tree_node_used; 
string = [];

for i = 1 : numel(trees)
    
    fprintf('compose_treeline_string, processing tree %d\n', i);
    
    tree_node_used = zeros(numel(trees{i}.nodes));
    t2_node_string = compose_nodes_string(trees{i}.nodes, [], 0);
    
    string = sprintf('%s\t\t<t2_treeline\n', string);
    string = sprintf('%s\t\t\toid="%d"\n', string, trees{i}.oid);
    string = sprintf('%s\t\t\twidth="%.1f"\n', string, layer_width);
    string = sprintf('%s\t\t\theight="%.1f"\n', string, layer_height);
    string = sprintf('%s\t\t\ttransform="matrix(1.0,0.0,0.0,1.0,0.0,0.0)"\n', string);
    string = sprintf('%s\t\t\tlocked="true"\n', string);
    string = sprintf('%s\t\t\ttitle="treeline"\n', string);
    string = sprintf('%s\t\t\tlinks=""\n', string);
    string = sprintf('%s\t\t\tlayer_set_id="%d"\n', string, layer_set_id);
    string = sprintf('%s\t\t\tstyle="fill:none;stroke-opacity:1.0;stroke:#ffff00;stroke-width:1.0px;stroke-opacity:1.0"\n', string);
    string = sprintf('%s\t\t>\n', string);
    string = sprintf('%s%s', string, t2_node_string);
    string = sprintf('%s\t\t</t2_treeline>\n', string);
    
end

end

function string = compose_nodes_string(tree, string, prev_node_id)

global lid tree_node_used;

if ~prev_node_id
    seed_id = find(cellfun(@(x) strcmp(x,'seed'), {tree.comment})); 
    current_nodes = seed_id;
    
    if numel(seed_id)~=1
        fprintf('  not unique seed: ');
        fprintf('%d ', seed_id);
        fprintf('\n');
    end
else
    current_nodes = [tree(prev_node_id).children tree(prev_node_id).parent];
    current_nodes = setdiff(current_nodes, find(tree_node_used)); 
end

if isempty(current_nodes)
    return;
end

for i = 1:numel(current_nodes)
   
    this_node_id = current_nodes(i); 
    tree_node_used(this_node_id) = 1;
    
    is_this_node_leaf = isempty(tree(this_node_id).children);
    has_comment = ~isempty(tree(this_node_id).comment);
    x = tree(this_node_id).x;
    y = tree(this_node_id).y;
    z = min( round(tree(this_node_id).z), 285 );

    if is_this_node_leaf && ~has_comment
        string_line = sprintf('\t\t\t<t2_node x="%.1f" y="%.1f" lid="%d" />', x, y, lid(z));
    else
        string_line = sprintf('\t\t\t<t2_node x="%.1f" y="%.1f" lid="%d">', x, y, lid(z));    
    end
    string = sprintf('%s%s\n', string, string_line);

    if has_comment
        string_line = sprintf('\t\t\t <t2_tag name="%s" key="%s" />', tree(this_node_id).comment, tree(this_node_id).comment);
        string = sprintf('%s%s\n', string, string_line);
    end

    string = compose_nodes_string(tree, string, this_node_id);
    
    if ~(is_this_node_leaf && ~has_comment)
        string = sprintf('%s\t\t\t</t2_node>\n', string);
    end
    
end

end


function trees = get_trees_from_nml(nml_file_list)

global id_count;

for i = 1 : numel(nml_file_list)

    file_name = fullfile(nml_file_list(i).folder, nml_file_list(i).name);
    s = xml2struct(file_name);

    nodes = [];
    
    for j = 1 : numel(s.things.thing.nodes.node)
        id = str2double(s.things.thing.nodes.node{j}.Attributes.id) + 1;
        nodes(id).x = str2double(s.things.thing.nodes.node{j}.Attributes.x); 
        nodes(id).y = str2double(s.things.thing.nodes.node{j}.Attributes.y); 
        nodes(id).z = str2double(s.things.thing.nodes.node{j}.Attributes.z); 
        nodes(id).children = [];
        nodes(id).parent = [];
        nodes(id).comment = [];
    end

    for j = 1 : numel(s.things.thing.edges.edge)
        id1 = str2double(s.things.thing.edges.edge{j}.Attributes.source) + 1;
        id2 = str2double(s.things.thing.edges.edge{j}.Attributes.target) + 1;
        nodes(id1).children = [nodes(id1).children id2];
        nodes(id2).parent = id1;
    end
   
    if isfield(s.things.comments, 'comment')
        if ~iscell(s.things.comments.comment)
            comment{1} = s.things.comments.comment;
        else
            comment = s.things.comments.comment;
        end
        for j = 1 : numel(comment)
            id = str2double(comment{j}.Attributes.node) + 1;
            nodes(id).comment = comment{j}.Attributes.content;
        end
    end
    
    id_count = id_count + 1;
    trees{i}.id = id_count;
    id_count = id_count + 1;
    trees{i}.oid = id_count;
    trees{i}.nodes = nodes;

    isolated_nodes = find_isolated_nodes(nodes);
    
    fprintf('get_trees_from_nml, processing tree %d: %s\n', i, file_name);
    if ~isempty(isolated_nodes)
        fprintf('  has isolated nodes: \n   ');
        fprintf('%d,', isolated_nodes);
        fprintf('\n');
    end
    
end

end

function isolated_nodes = find_isolated_nodes(tree)

cluster_id_of_node = 1 : numel(tree);
for i = 1 : numel(tree)
    n1 = i; 
    for j = 1 : numel(tree(i).children)
        n2 = tree(i).children(j);
        cluster1 = cluster_id_of_node(n1);
        cluster2 = cluster_id_of_node(n2);
        cluster_id_of_node(cluster_id_of_node==cluster2) = cluster1;
    end
end

[count_in_cluster,cluster_ids] = hist(cluster_id_of_node, unique(cluster_id_of_node));

[~, idx] = max(count_in_cluster); 

isolated_nodes = find(cluster_id_of_node~=cluster_ids(idx));
isolated_nodes(cellfun(@(x) isempty(x), {tree(isolated_nodes).x})) = [];

end

