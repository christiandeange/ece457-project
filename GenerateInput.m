function [Courses Students Rooms Teachers Events] = GenerateInput( numDays, numTimeSlots, numCourses, numStudents, numRooms, numTeachers, numEvents, numFeatures )
    %GENERATEINPUT Summary of this function goes here
    %   Detailed explanation goes here
    % e.g. [courses students rooms teachers events] = GenerateInput(5,6,5,4,15,5,5,5)
    %TODO: actually assign stuff to them (reqs, enrollment, etc)
    
    Features = RoomFeature.empty(numFeatures, 0);
    Courses = Course.empty(numCourses,0);
    Students = Student.empty(numStudents,0);
    Rooms = Classroom.empty(numRooms,0);
    Teachers = Teacher.empty(numTeachers,0);
    Events = Event.empty(numEvents,0);
        
    for i = 1:numFeatures
       Features(i) = RoomFeature(i);
    end
    
    for i = 1:numRooms
       Rooms(i) = createRandRoom(i, numStudents, Features); 
    end
    
    for i = 1:numTeachers
        %do empty for both, do courses taught when creating courses and
        %events when creating events
       Teachers(i) = Teacher(i, [], []); 
    end
    
    for i = 1:numCourses
       
       [Courses(i) Teachers] = createRandCourse(i, numTimeSlots, Features, Teachers); 
    end
    
    for i = 1:numStudents
       Students(i) = createRandStudent(i, Courses); 
    end
    
    for i = 1:numEvents
       [Events(i) Students Teachers] = createRandEvent(i, Students, Teachers, numTimeSlots); 
    end
    
end

%random features and capacity
function [randClassroom] = createRandRoom(i, numStudents, Features)
    randNumFeatures = round(length(Features)*rand);
    randFeatures = randsample(Features,randNumFeatures);
    randCapacity = round(numStudents*rand + 0.5);
    randClassroom = Classroom(i, randFeatures, randCapacity);
end

%random features and duration
function [randCourse newTeachers] = createRandCourse(i, numTimeSlots, Features, Teachers)
    randNumFeatures = round(length(Features)*rand);
    randFeatures = randsample(Features,randNumFeatures);
    randDuration = round(numTimeSlots*rand + 0.5);
    
    randCourse = Course(i, randFeatures, randDuration);
    
    randTeacher = round(length(Teachers) * rand + 0.5);
    Teachers(randTeacher).classesTaught = [Teachers(randTeacher).classesTaught, randCourse];
    
    newTeachers = Teachers;
end

%random courses taken and empty events(add in when creating events)
function [randStudent] = createRandStudent(i, Courses)
    randNumCourses = round((length(Courses)/2) * rand + 0.5);
    randCourses = randsample(Courses, randNumCourses);
    randStudent = Student(i, randCourses, []);
end

%pick random teacher, student duration
function [randEvent newStudents newTeachers] = createRandEvent(i, Students, Teachers, numTimeSlots)
    randStudent = round(length(Students) * rand + 0.5);
    randTeacher = round(length(Teachers) * rand + 0.5);
    randDuration = round(numTimeSlots * rand + 0.5);
  
    randEvent = Event(i, randTeacher, randStudent, randDuration);
    
    Students(randStudent).eventsAttended = [Students(randStudent).eventsAttended, randEvent];
    newStudents = Students;
    
    Teachers(randTeacher).eventsAttended = [Teachers(randTeacher).eventsAttended, randEvent];
    newTeachers = Teachers;
end
































