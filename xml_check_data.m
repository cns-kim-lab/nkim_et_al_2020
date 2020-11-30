function check_data(tree, tree_id, v)

% tree = tree = parse_trakem2_xml_to_sktree(s);

treenodes = readtable(sprintf('treelines/%d',tree_id), 'Delimiter', '\t ', 'ReadVariableNames', false);

X_txt = double(treenodes.Var2);
Y_txt = double(treenodes.Var3);
Z_txt = double(treenodes.Var5); 

tree_ids = cellfun(@(x) x.tree_id, tree)';
tree_id = find(tree_ids == tree_id);

for i = 1 : numel(tree{tree_id}.nodes)

    X_tree = tree{tree_id}.nodes(i).x;
    Y_tree = tree{tree_id}.nodes(i).y;
    Z_tree = tree{tree_id}.nodes(i).z;
    
    X = X_txt - repmat(X_tree,size(X_txt)); 
    Y = Y_txt - repmat(Y_tree,size(Y_txt)); 
    Z = Z_txt - repmat(Z_tree,size(Z_txt));
    dist = sqrt(X.*X + Y.*Y + Z.*Z); 

    idx = find(dist<1);

    if ~v
        if numel(idx)~=1
            fprintf('%d: %d\n', i, numel(idx));
        end
    else
        fprintf('%d\t%f\t%f\t%f\t%s, %s\n', ...
            i, ...
            tree{tree_id}.nodes(i).x, ...
            tree{tree_id}.nodes(i).y, ...
            tree{tree_id}.nodes(i).z, ...
            tree{tree_id}.nodes(i).key, ...
            tree{tree_id}.nodes(i).name);

        for j = 1:numel(idx)
            fprintf('  >  %d (%f): ',idx(j), dist(idx(j))); 

            fprintf('%f\t%f\t%f\t%s\n', ...
                treenodes.Var2(idx(j)), ...
                treenodes.Var3(idx(j)), ...
                treenodes.Var5(idx(j)), ...
                treenodes.Var9{idx(j)});

        end
    end
    
end



end
