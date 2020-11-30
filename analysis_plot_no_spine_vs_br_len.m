
clear all;

dir_path = '/data/research/jk/rah_narikim/trakem2_project_files_synapse/';
tree_ids = [ 1002, 1004, 1006, 1008, 1014, 1016, 1018, 1020, 1022, 1024, 1026, 1028, 1030, 1032, 1034, 1036, 1038, 1040 ];

file_names{1} = 'trakem2_ch1234_tracing_1002end_03.xml';
% file_names{2} = 'trakem2_ch1234_tracing_1004end_omni_03.xml';
% file_names{3} = 'trakem2_ch1234_tracing_1006end_omni_05.xml';
% file_names{4} = 'trakem2_ch1234_tracing_1008end_omni_05.xml';
% file_names{5} = 'trakem2_ch1234_tracing_1014end_omni_02.xml';
% file_names{6} = 'trakem2_ch1234_tracing_1016end_omni_04.xml';
% file_names{7} = 'trakem2_ch1234_tracing_1018end_omni_04.xml';
% file_names{8} = 'trakem2_ch1234_tracing_1020end_omni_05.xml';
% file_names{9} = 'trakem2_ch1234_tracing_1022end_omni_04.xml';
% file_names{10} = 'trakem2_ch1234_tracing_1024end_omni_06.xml';
% file_names{11} = 'trakem2_ch1234_tracing_1026end_omni_05.xml';
% file_names{12} = 'trakem2_ch1234_tracing_1028end_omni_05.xml';
% file_names{13} = 'trakem2_ch1234_tracing_1030end_omni_03.xml';
% file_names{14} = 'trakem2_ch1234_tracing_1032end_omni_05.xml';
% file_names{15} = 'trakem2_ch1234_tracing_1034end_omni_03.xml';
% file_names{16} = 'trakem2_ch1234_tracing_1036end_omni_03.xml';
% file_names{17} = 'trakem2_ch1234_tracing_1038end_omni_04.xml';
% file_names{18} = 'trakem2_ch1234_tracing_1040end_omni_06.xml';

for i = 1 : numel(file_names) 
   
    full_path = sprintf( '%s/%s' , dir_path , file_names{i} );
    fprintf( 'file %d: %s\n' , i , full_path );
    s = xml2struct( full_path );
    this_tree = trakem2_xml_to_sktree( s , tree_ids(i) );
    tree{i} = this_tree{:};  %#ok<SAGROW>

end

tree_with_synapse = xml_sktree_separate_synapse( tree );
[ dendrite_branchlets , tree_with_projected_synapse ] = analysis_split_dendrite_branchlets( tree_with_synapse , [] );
tree_with_projected_synapse = analysis_get_distance_from_root( tree_with_projected_synapse );
dendrite_branchlets = analysis_get_branchlet_metadata( tree_with_synapse , dendrite_branchlets );


% branchlet_lengths = [];
% number_of_synapses_1 = [];
% number_of_synapses_2 = [];
% number_of_synapses_sum = [];
% 
% idx = 0;
% for i = 1 : numel( dendrite_branchlets )
%     
%     branchlet_lengths = [ branchlet_lengths [dendrite_branchlets(i).branchlets(:).path_length] ];  %#ok<*AGROW>
%     
%     for j = 1 : numel ( dendrite_branchlets(i).branchlets )
%         
%         idx = idx + 1; 
%         
%         num1 = 0;
%         num2 = 0;
%         if ~isempty(dendrite_branchlets(i).branchlets(j).spines)
%             num1 = sum( [dendrite_branchlets(i).branchlets(j).spines.type] == 1);
%             num2 = sum( [dendrite_branchlets(i).branchlets(j).spines.type] == 2);
%         end
%         number_of_synapses_1( idx ) = num1; %#ok<SAGROW>
%         number_of_synapses_2( idx ) = num2; %#ok<SAGROW>
%         number_of_synapses_sum( idx ) = num1 + num2; %#ok<SAGROW>
%         
%     end
% end

% graph 1 : #synapses / branchlet_length bin stack bar graph
% edges = 0:25:600;
% [ ~ , ~ , loc ] = histcounts( branchlet_lengths , edges );
% mean_number_1 = accumarray( loc(:), number_of_synapses_1(:) ) ./ accumarray( loc(:) , 1 );
% mean_number_2 = accumarray( loc(:), number_of_synapses_2(:) ) ./ accumarray( loc(:) , 1 );
% mean_number_sum = accumarray( loc(:), number_of_synapses_sum(:) ) ./ accumarray( loc(:) , 1 );
% xmid = 0.5 * ( edges(1:end-1) + edges(2:end) );
% 
% mean_number_1(22:24) = 0;
% mean_number_2(22:24) = 0;
% mean_number_sum(22:24) = 0;
% mean_number_1(isnan(mean_number_1)) = 0;
% mean_number_2(isnan(mean_number_2)) = 0;
% mean_number_sum(isnan(mean_number_sum)) = 0;
% 
% bar( xmid , [mean_number_1 mean_number_2] , 'stacked' );

% nbins = 20;
% synapse_density_1 = number_of_synapses_1 ./ branchlet_lengths;
% synapse_density_2 = number_of_synapses_2 ./ branchlet_lengths;
% synapse_density_sum = number_of_synapses_sum ./ branchlet_lengths;
% 
% [histcount_num_1 , ~] = histcounts(synapse_density_1, nbins);
% [histcount_num_2 , ~] = histcounts(synapse_density_2, nbins);
% [histcount_num_sum , edges] = histcounts(synapse_density_sum, nbins);
% 
% [histcount_den_1 , ~] = histcounts(number_of_synapses_1, nbins);
% [histcount_den_2 , ~] = histcounts(number_of_synapses_2, nbins);
% [histcount_den_sum , edges] = histcounts(number_of_synapses_sum, nbins);
% 
% xmid = 0.5 * ( edges(1:end-1) + edges(2:end) );
% figure(1); plot( xmid , histcount_num_1 , xmid , histcount_num_2 , xmid , histcount_num_sum );
% figure(2); plot( xmid , histcount_den_1 , xmid , histcount_den_2 , xmid , histcount_den_sum );


% branchlet_length input1 input2 
input1_all_trees = sum([dendrite_branchlets.num_input1]);
input2_all_trees = sum([dendrite_branchlets.num_input2]);

for i = 1 : numel( dendrite_branchlets )

    input1_this_tree = dendrite_branchlets(i).num_input1;
    input2_this_tree = dendrite_branchlets(i).num_input2;
        
    for j = 1 : numel ( dendrite_branchlets(i).branchlets )
        length = dendrite_branchlets(i).branchlets(j).path_length;
        num_input1 = dendrite_branchlets(i).branchlets(j).num_input1;
        num_input2 = dendrite_branchlets(i).branchlets(j).num_input2;
        norm1_input1 = num_input1 / input1_this_tree; 
        norm1_input2 = num_input2 / input2_this_tree; 
        norm2_input1 = num_input1 / input1_all_trees;
        norm2_input2 = num_input2 / input2_all_trees;
        
        r1 = abs( num_input1 - num_input2 ) / ( num_input1 + num_input2 );
        r2 = abs( norm1_input1 - norm1_input2 ) / ( norm1_input1 + norm1_input2 );
        r3 = abs( norm2_input1 - norm2_input2 ) / ( norm2_input1 + norm2_input2 );
        
        t = dendrite_branchlets(i).branchlets(j).is_terminal;
        
        if num_input1==0 && num_input2==0
            continue;
        end
        fprintf( '%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%d\n', ...
                               length , num_input1 , norm1_input1 , norm2_input1, ...
                               num_input2 , norm1_input2 , norm2_input2, ...
                               r1 , r2 , r3 , t);
    end

end


