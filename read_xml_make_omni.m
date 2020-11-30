
function read_xml_make_omni( input_file_name , output_file_name , trees_to_draw )

% input_file = 'trakem2_project_files_synapse/trakem2_ch1234_tracing.xml'; 

fprintf('reading xml file ...\n');
s = xml2struct( input_file_name );

fprintf('converting xml to tree ...\n');
tree = trakem2_xml_to_sktree( s );

fprintf('separating dendrites and inputs ...\n');
tree_with_synapse = xml_sktree_separate_synapse( tree );

fprintf('drawing tree ...\n');
seg_size_in = [2304 3200 384];
draw_sktree_with_synapse_on_seg( tree_with_synapse , seg_size_in , output_file_name , trees_to_draw ); 

end