class AppController < ApplicationController
  def new
  end

  def show # отображение информации о записи
    @seance = Seance.find(params[:seance_id])
    @client = @seance.client
  end

  def db # метод, выполняющий запросы к БД
    case params[:to_find]
    when 'doctor'
      # находим все сеансы в выбранный день
      @result = Seance.where("to_char(date, 'DD-MM-YYYY') = ? and affilate_id = ?", params[:date], params[:affilate])
      # извлекаем только свободные сеансы
      @result = @result.select { |p| p.client.nil? }
      # извлекаем список врачей без повторов
      @result = @result.collect(&:doctor).uniq
      # извлекаем ФИО врача
      @result = @result.collect { |p| [p.full_name + ((rank = p.rank).nil? ? '' : (' — ' + rank)), p.id] }
      @result = [['Нет cвободных врачей']] if @result.blank?
    when 'seance'
      # находим все сеансы выбранного врача в выбранный день
      @result = Seance.where("to_char(date, 'DD-MM-YYYY') = ? and doctor_id = ?", params[:date], params[:doctor_id])
      # извлекаем время свободных сеансов
      @result = @result.select { |p| p.client.nil? }.collect { |p| [p.date.strftime('%H:%M'), p.id] }
      @result = [['—']] if @result.blank?
    when 'is_schedule'
      # находим все сеансы выбранного врача в выбранный день
      @query = Seance.where("to_char(date, 'DD-MM-YYYY') = ? and doctor_id = ?", params[:date], params[:doctor_id])
      # определяем наличие сеансов
      @result = @query.blank? ? [['-']] : [['+']]
    end
    @result = [['Нет доступных вариантов']] if @result.blank?
    render json: @result # рендерим JSON, который получит клиент
  end

  def add # метод, заполняющий поля БД
    # проверяем, зарегистрирован ли пациент в базе
    @client = Client.where('name = ? and last_name = ? and phone = ?', params[:name], params[:last_name], params[:phone])[0]
    if @client.nil?
      # создаём новую запись пациента в БД и заполнияем поля
      @client = Client.new(:last_name => params[:last_name], 
                          :name => params[:last_name],
                          :patronymic => params[:patronymic],
                          :birthdate => params[:birthdate],
                          :email => params[:email],
                          :phone => params[:phone],
                          :is_moscow => params[:is_moscow])
    end
    if @client.valid?
      # находим сеанс, на который производится запись и задаём пациента
      @seance = Seance.find(params[:seance])
      if !@seance.nil? && @seance.client.nil?
        @seance.client = @client
        @seance.save
        # перенаправление на страницу с информацией о записи
        redirect_to action: 'show', seance_id: @seance.id
      else
        redirect_to root_path(message: "Выбран некорректный сеанс")
      end
    else
      redirect_to root_path(message: "Введены некорректные данные")
    end
  end
end
