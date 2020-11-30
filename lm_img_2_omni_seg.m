
function lm_img_2_omni_seg()

img_thr = 20;
cc_thr = 100;

seg_size = [2273,3128,285];
img_ch_in = zeros(seg_size([2 1 3]),'uint8');
seg = zeros(seg_size,'uint32');


for j=1:4
    
    for i=1:285
        filename = sprintf('aligned_channels_skbahndir/ch%d/%04d.tif',j,i); 
        img_ch_in(:,:,i) = imread(filename);
    end
    img_ch = double(permute(img_ch_in, [2 1 3]));

    % normalize
%     img_ch_nonzeroes = img_ch(img_ch(:)~=0);
%     cut_min = prctile(img_ch_nonzeroes, 2);
%     cut_max = prctile(img_ch_nonzeroes, 98);

    cut_min = 2;
    if j == 4 
        cut_max = 70;   % channel_4
    else
        cut_max = 100;
    end
    
    img_ch = max( min( (img_ch - cut_min)/(cut_max - cut_min)*255, 255), 0); 
    
    for i=1:285
        filename = sprintf('enhanced_images/ch%d/%04d.tif',j,i); 
        img_ch_in = double(img_ch(:,:,i))/255; 
        img_ch_in = permute(img_ch_in, [2 1 3]);
        imwrite(img_ch_in, filename);
    end
    
%     hdf5write(sprintf('channel_%d.h5',j),'/main',uint8(img_ch));

end

% 
% for j=3:3
%     
%     for i=1:285
%         filename = sprintf('aligned_channels_skbahndir/ch%d/%04d.tif',j,i); 
%         img_ch_in(:,:,i) = imread(filename);
%     end
%     img_ch = permute(img_ch_in, [2 1 3]);
%     
%     bw_cc = bwconncomp(img_ch>img_thr, 18);    
%     bw_cc_PixelIdxList = bw_cc.PixelIdxList;
%     bw_cc_PixelIdxList(cellfun(@(x) numel(x), bw_cc_PixelIdxList) < cc_thr) = [];
% 
%     for i=1:numel(bw_cc_PixelIdxList)
%         [x,y,z]=ind2sub(seg_size,bw_cc_PixelIdxList{i});
%         if numel(unique(z))<2
%             continue;
%         end
%         seg(bw_cc_PixelIdxList{i}) = j*10^5 + i;
%     end
% 
% end
% 
% seg(1,1,1)=1;
% seg(1,1,2)=100001;
% seg(1,1,3)=200001;
% 
% hdf5write('segment_3.h5','/main',seg);
% 
