class LessonsController < ApplicationController
	skip_before_filter :authorize, except: [:new, :edit, :destroy]

def index
	# redirect_to "lessons/2"
	@lessons = Lesson.all
	#Lesson.find_by_secret_code asdfasdf
end

def new
end

def create
	# binding.pry
	course = Course.find_by_secret_code(params[:course_id])
	# binding.pry
	lesson = Lesson.create(title: params[:lesson], course_id: course.id, secret_code: SecureRandom.urlsafe_base64)
	# when lesson create, set secret code as attribute of class
	# binding.pry
	unless params["keyHash"] == nil
		params["keyHash"].each do |num1, key_info|
			k = KeyConcept.create(info: key_info, lesson_id: lesson.id)
			unless params["subHash"] == nil
				params["subHash"].each do |sub_info, num2|
					if num2 == num1
						SubConcept.create(info: sub_info, key_concept_id: k.id)
					end
				end
			end
		end
	end
	# binding.pry
	redirect_to course_path(params[:course_id])

end

def show
	@lesson = Lesson.find_by_secret_code(params[:id])
	# binding.pry
	@concepts = {}
	@key_concepts = KeyConcept.where(lesson_id: @lesson.id)
	@key_concepts.each do |key_concept|
		@sub_concepts = SubConcept.where(key_concept_id: key_concept.id)
		@concepts[key_concept] = @sub_concepts
	end

	# This adds the ratings cookie to make sure students can only vote once per item
	# Cookie needs to be array, but browser saves as strings, so we need special methods to convert it
	# Methods defined in application controller
	if read_cookies.empty?
		write_cookies([])
	end
end

def edit
end

def update
	@sub_concept = SubConcept.find(params[:id])

	# The first time needs ratingCount to be set because it gives errors when adding 1 to nil
	if @sub_concept.ratingCount == nil
		@sub_concept.update_attributes(ratingAverage: params[:rating])		
		@sub_concept.update_attributes(ratingCount: 1)

		cookies = read_cookies
		cookies << @sub_concept.id
		write_cookies(cookies)
	else
		@sub_concept.update_attributes(ratingAverage: ((@sub_concept.ratingCount * @sub_concept.ratingAverage + params[:rating].to_f) / (@sub_concept.ratingCount.to_f + 1)).round(2) )
		@sub_concept.update_attributes(ratingCount: @sub_concept.ratingCount + 1)

		cookies = read_cookies
		cookies << @sub_concept.id
		write_cookies(cookies)
	end
	lesson = @sub_concept.key_concept.lesson.secret_code

	redirect_to "/lessons/" + lesson
end

def destroy
	lesson = Lesson.find(params[:id])
	course = lesson.course
	Lesson.destroy(params[:id])
	redirect_to course_path(course.secret_code)
end
end
