<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.application.component.modellist');

    class LrgalleryModelMetadatas extends JModelList
    {
        protected function getListQuery()
        {
            $db = JFactory::getDBO();
            $query = $db->getQuery(true);
            $query->select('mdata.photo_id, p.name as photo_name, 
                 mdata.meta_id, m.name as meta_name, m.desc, mdata.value');
            $query->from('#__lrgallery_metadata mdata, #__lrgallery_meta m, #__lrgallery_photos p');
            $query->where('mdata.photo_id = p.id and mdata.meta_id = m.id');
            
            return $query;
        }
    }
?>