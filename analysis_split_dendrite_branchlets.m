
function [ dendrite_branchlets , tree_with_projected_synapse ] = analysis_split_dendrite_branchlets( tree_with_synapse , tree_ids )

% tree_with_synapse = xml_sktree_separate_synapse( tree );

if ~isempty( tree_ids )
    num_trees = numel(tree_ids);
else
    num_trees = numel(tree_with_synapse);
end

idx_tree = 0;
tree_with_projected_synapse = tree_with_synapse; 

for i = 1 : numel( tree_with_synapse )
    
    this_tree = tree_with_synapse{i};
    this_tree_id = this_tree.tree_id; 
    
    if ~isempty( tree_ids )
        if ~ismember( this_tree_id, tree_ids )
            continue;
        end
    end

    idx_tree = idx_tree + 1;
    fprintf( 'tree: %d/%d \n' , idx_tree , num_trees );
        
    % prune spine branches
    is_spine_node = logical([this_tree.nodes.spine]);
    for j = 1 : numel(this_tree.nodes)
        if (tree_with_projected_synapse{i}.nodes(j).spine)
            tree_with_projected_synapse{i}.nodes(j).parent = [];
        end
        
        nodes_to_del = is_spine_node( this_tree.nodes(j).children ); 
        if ~isempty( nodes_to_del )
            tree_with_projected_synapse{i}.nodes(j).children( nodes_to_del ) = [];
        end            
    end        
    
    % split dendritic branchlets at each branching point
    dendrite_branchlets(idx_tree).tree_id = this_tree_id;   %#ok<AGROW>
    dendrite_branchlets(idx_tree).branchlets = [];          %#ok<AGROW>
    
    root_node = find( [this_tree.nodes.parent] == 0 );
    arbored_branchlet_starting_nodes = root_node; 
    arboring_nodes = 0;
    
    while ~isempty(arbored_branchlet_starting_nodes)
        
        current_node = arbored_branchlet_starting_nodes(1); 
        next_all_nodes = this_tree.nodes(current_node).children; 
        next_spine_nodes = next_all_nodes( is_spine_node( next_all_nodes ) );
        next_shaft_nodes = setdiff( next_all_nodes , next_spine_nodes );

        this_branchlet_shaft_nodes = current_node;
        this_branchlet_spine_starting_nodes = next_spine_nodes;

        % trace the shaft nodes
        while numel( next_shaft_nodes ) == 1
            current_node = next_shaft_nodes(1);
            next_all_nodes = this_tree.nodes(current_node).children; 
            next_spine_nodes = next_all_nodes( is_spine_node( next_all_nodes ) );
            next_shaft_nodes = setdiff( next_all_nodes , next_spine_nodes );            

            this_branchlet_shaft_nodes = [ this_branchlet_shaft_nodes , current_node ];	%#ok<AGROW>
            this_branchlet_spine_starting_nodes = [ this_branchlet_spine_starting_nodes , next_spine_nodes ]; %#ok<AGROW>
        end

        % save this branchlet nodes. exception root node case
        if arboring_nodes(1) == 0 
            dendrite_branchlets(idx_tree).branchlets(end + 1).nodes = this_branchlet_shaft_nodes; 
        else
            dendrite_branchlets(idx_tree).branchlets(end + 1).nodes = [ arboring_nodes(1), this_branchlet_shaft_nodes ]; 
        end

        this_branchlet_all_nodes = dendrite_branchlets(idx_tree).branchlets(end).nodes; 

        for j = 1 : numel( this_branchlet_spine_starting_nodes )
            
            [ projected_coord_voxel , parent , child ] = project_synapse_onto_branchlet( ...
                tree_with_projected_synapse{i} , this_branchlet_all_nodes , this_branchlet_spine_starting_nodes(j) );

            new_node_id = numel(tree_with_projected_synapse{i}.nodes) + 1; 
            projected_coord_physical = projected_coord_voxel .* [ 110 110 85 ];
            tree_with_projected_synapse{i}.nodes(new_node_id).voxel_x = projected_coord_voxel(1);
            tree_with_projected_synapse{i}.nodes(new_node_id).voxel_y = projected_coord_voxel(2);
            tree_with_projected_synapse{i}.nodes(new_node_id).voxel_z = projected_coord_voxel(3); 
            tree_with_projected_synapse{i}.nodes(new_node_id).physical_x  = projected_coord_physical(1);
            tree_with_projected_synapse{i}.nodes(new_node_id).physical_y  = projected_coord_physical(2);
            tree_with_projected_synapse{i}.nodes(new_node_id).physical_z  = projected_coord_physical(3);
            tree_with_projected_synapse{i}.nodes(new_node_id).parent = parent;
            tree_with_projected_synapse{i}.nodes(new_node_id).children = child;
            tree_with_projected_synapse{i}.nodes(new_node_id).spine = this_tree.nodes(this_branchlet_spine_starting_nodes(j)).spine; 
            
            idx_child_node = ( tree_with_projected_synapse{i}.nodes(parent).children == child );
            tree_with_projected_synapse{i}.nodes(parent).children(idx_child_node) = new_node_id; 
            tree_with_projected_synapse{i}.nodes(child).parent = new_node_id; 
            
            idx_insert_loc = find( this_branchlet_all_nodes == parent );
            this_branchlet_all_nodes = [ this_branchlet_all_nodes( 1 : idx_insert_loc ) new_node_id this_branchlet_all_nodes( idx_insert_loc + 1 : end) ];
                
            dendrite_branchlets(idx_tree).branchlets(end).spines(j).coord_physical = projected_coord_physical;
            dendrite_branchlets(idx_tree).branchlets(end).spines(j).coord_voxel = projected_coord_voxel;
            dendrite_branchlets(idx_tree).branchlets(end).spines(j).type = this_tree.nodes(this_branchlet_spine_starting_nodes(j)).spine; 

        end
        
        if numel(next_shaft_nodes) > 1
            arboring_nodes = [ arboring_nodes, repmat( current_node, 1, numel(next_shaft_nodes) ) ];  %#ok<AGROW>
            arbored_branchlet_starting_nodes = [ arbored_branchlet_starting_nodes, next_shaft_nodes ];    %#ok<AGROW>
        end        
        arboring_nodes(1) = [];
        arbored_branchlet_starting_nodes(1) = [];
        
    end

end

end

function [ voxel_coord , parent , child ] = project_synapse_onto_branchlet( tree , branchlet_nodes , synapse_starting_node )

current_node = synapse_starting_node;
next_node = tree.nodes(current_node).children; 
        
while numel( next_node ) >= 1
    if numel( next_node) > 1
        fprintf('more than one branch in spine: %d\n', next_node);
    end
    current_node = next_node(1);
    next_node = tree.nodes(current_node).children; 
end

if isempty(next_node)
    synapse_end_node = current_node;
else
    synapse_end_node = next_node; 
end

% find two closest branchlet nodes from the synapse node
X = [ [tree.nodes(branchlet_nodes).voxel_x]' , [tree.nodes(branchlet_nodes).voxel_y]' , [tree.nodes(branchlet_nodes).voxel_z]' ]; 
y = [tree.nodes(synapse_end_node).voxel_x , tree.nodes(synapse_end_node).voxel_y , tree.nodes(synapse_end_node).voxel_z ];
Y = repmat( y , size(X,1) , 1 );
X = X - Y; 
distance_to_nodes = sqrt( sum( X.*X , 2) );
[~, idx_min] = min( distance_to_nodes );
closest_nodes(1) = branchlet_nodes( idx_min ); 

next_closest_cands = [];
if idx_min > 1
    next_closest_cands = [ next_closest_cands , idx_min - 1 ];   % note parent-child order in "branchlet_nodes"
end
if idx_min < numel(branchlet_nodes)
    next_closest_cands = [ next_closest_cands , idx_min + 1 ]; 
end
[~, idx_min] = min( distance_to_nodes( next_closest_cands ) );
closest_nodes(2) = branchlet_nodes( next_closest_cands(idx_min) );

if tree.nodes(closest_nodes(1)).parent == closest_nodes(2)
    parent = closest_nodes(2);
    child = closest_nodes(1);
elseif tree.nodes(closest_nodes(2)).parent == closest_nodes(1)
    parent = closest_nodes(1);
    child = closest_nodes(2);
else
    fprintf( 'error : %d %d parent child cannot be determined\n' , closest_nodes(1) , closest_nodes(2) );
end

a = [ tree.nodes(closest_nodes(1)).voxel_x , tree.nodes(closest_nodes(1)).voxel_y , tree.nodes(closest_nodes(1)).voxel_z ];
b = [ tree.nodes(closest_nodes(2)).voxel_x , tree.nodes(closest_nodes(2)).voxel_y , tree.nodes(closest_nodes(2)).voxel_z ];
c = y; 
ab = b - a; 
t = -(a - c)*(ab.') / (ab*ab.'); % -(x1 - x0).(x2 - x1) / (|x2 - x1|^2)

if t>=0 && t<=1
    voxel_coord = a + (b - a)*t;
else
    voxel_coord = a; 
end

end

