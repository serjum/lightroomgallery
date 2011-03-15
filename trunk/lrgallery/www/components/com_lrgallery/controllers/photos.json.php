<?php
    // no direct access
    defined('_JEXEC') or die;

    jimport('joomla.application.component.controllerform');

    class LrgalleryControllerPhotos extends JControllerForm
    {
        /*
         * Название поля метаданных "Флаг принятия" 
         */
        const metaAccepted = "accepted";
        
        /*
         * Название поля метаданных "Рейтинг" 
         */
        const metaRating = "rating";
        
        /*
         * Название поля метаданных "Комментарии" 
         */
        const metaComments = "comments";
        
        /*
         * Проверка, проставлено ли уже значение поля метаданных у фотографии
         */
        private function checkMetadata($id, $metaName)
        {
            $db =& JFactory::getDBO();
            $metaNameQ = $db->quote($metaName);
            $db->setQuery("SELECT meta_id
                             FROM #__lrgallery_metadata
                            WHERE photo_id = $id
                              AND meta_id = (
                                    SELECT id
                                      FROM #__lrgallery_meta
                                     WHERE name = $metaNameQ)");
            return $db->loadResult();
        }
        
        /*
         * Вставка нового значения поля метаданных
         */
        private function insertMetadata($id, $metaName, $data)
        {
            $db =& JFactory::getDBO();
            $metaNameQ = $db->quote($metaName);
            $dataQ = $db->quote($data);
            $db->setQuery("INSERT INTO #__lrgallery_metadata
                                (photo_id, meta_id, value)
                               VALUES
                                ($id, (SELECT id
                                         FROM #__lrgallery_meta
                                        WHERE name = $metaNameQ), $dataQ)");
            $result = $db->query();
            return Array('Error' => !$result, 'Message' => $db->stderr());
        }
        
        /*
         * Обновление значения поля метаданных
         */
        private function updateMetadata($id, $metaId, $data)
        {
            $db =& JFactory::getDBO();
            $dataQ = $db->quote($data);
            $db->setQuery("UPDATE #__lrgallery_metadata
                                  SET value = $dataQ
                                WHERE photo_id = $id
                                  AND meta_id = $metaId");
            $result = $db->query();
            return Array('Error' => !$result, 'Message' => $db->stderr());
        }
        
        /*
         * Установка флага принятия для фотографии
         */
        public function setAcceptedFlag()
        {
            $id = JRequest::getInt('id');
            $flag = JRequest::getString('flag', 'none');
            
            $metaId = $this->checkMetadata($id, self::metaAccepted);
            if ($metaId)
                $result = $this->updateMetadata ($id, $metaId, $flag);
            else
                $result = $this->insertMetadata ($id, self::metaAccepted, $flag);
            
            $response = Array($result['Error'], 'Message' => $result['Message'], 'meta' => $flag);
            $document =& JFactory::getDocument();
            $document->setMimeEncoding( 'application/json' );
            JResponse::setHeader( 'Content-Disposition', 'attachment; filename="'.$this->getName().'.json"' );
            echo json_encode($response);
        }
        
        /*
         * Установка рейтинга фотографии
         */
        public function setRating()
        {
            $id = JRequest::getInt('id');
            $rating = JRequest::getString('rating', 'none');
            
            $metaId = $this->checkMetadata($id, self::metaRating);
            if ($metaId)
                $result = $this->updateMetadata ($id, $metaId, $rating);
            else
                $result = $this->insertMetadata ($id, self::metaRating, $rating);
            
            $response = Array($result['Error'], 'Message' => $result['Message'], 'meta' => $rating);
            $document =& JFactory::getDocument();
            $document->setMimeEncoding( 'application/json' );
            JResponse::setHeader( 'Content-Disposition', 'attachment; filename="'.$this->getName().'.json"' );
            echo json_encode($response);
        }
        
        /*
         * Установка комментариев фотографии
         */
        public function setComments()
        {
            
        }        
    }
?>    