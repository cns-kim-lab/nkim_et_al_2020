function prepare_seg_hdf5_file(out_vol_size, seg_hdf5_file_name)

size_of_chunk = [128 128 128];
out_vol_size_in_chunk = ceil(out_vol_size./size_of_chunk);

create_hdf5_file(seg_hdf5_file_name,'/main',out_vol_size,size_of_chunk,[0 0 0],'uint');
chunk=zeros(size_of_chunk,'uint32');

for x = 1:out_vol_size_in_chunk(1)
   for y = 1:out_vol_size_in_chunk(2)
       for z = 1:out_vol_size_in_chunk(3)
           st=([x y z]-1).*size_of_chunk+1;
           ed=[x y z].*size_of_chunk;
           fprintf('filling up [%d %d %d]\n',x,y,z);
           write_hdf5_file(seg_hdf5_file_name,'/main',st,ed,chunk); 
       end
   end
end    

end
